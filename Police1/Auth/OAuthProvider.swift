import Foundation
import AuthenticationServices

// MARK: - OAuth Provider

/// OAuth 2.0 / OpenID Connect authentication provider.
/// Supports Azure AD, Okta, Auth0, and other OAuth providers.
final class OAuthProvider: NSObject, AuthProvider {
    var currentSession: AuthSession?

    let displayName: String
    let usesExternalLoginUI = true

    private let config: OAuthConfig
    private let urlSession: URLSession

    // PKCE values for current auth flow
    private var codeVerifier: String?

    init(config: OAuthConfig, displayName: String = "Single Sign-On", urlSession: URLSession = .shared) {
        self.config = config
        self.displayName = displayName
        self.urlSession = urlSession
    }

    // MARK: - AuthProvider

    func login(with credentials: AuthCredentials) async throws -> AuthSession {
        guard let oauthCreds = credentials as? OAuthCodeCredentials else {
            throw AuthError.configurationError("OAuthProvider requires OAuthCodeCredentials")
        }

        return try await exchangeCodeForTokens(
            code: oauthCreds.authorizationCode,
            codeVerifier: oauthCreds.codeVerifier,
            redirectUri: oauthCreds.redirectUri
        )
    }

    func loginWithUI() async throws -> AuthSession {
        // Generate PKCE values
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        self.codeVerifier = verifier

        // Build authorization URL
        var components = URLComponents(string: config.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]

        if config.usePKCE {
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "code_challenge", value: challenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ])
        }

        guard let authUrl = components.url else {
            throw AuthError.configurationError("Invalid authorization URL")
        }

        // Present authentication session
        let callbackUrl = try await presentAuthSession(url: authUrl)

        // Extract authorization code from callback
        guard let code = extractCode(from: callbackUrl) else {
            throw AuthError.unknown("Failed to extract authorization code")
        }

        // Exchange code for tokens
        return try await exchangeCodeForTokens(
            code: code,
            codeVerifier: config.usePKCE ? verifier : nil,
            redirectUri: config.redirectUri
        )
    }

    func refreshSession() async throws -> AuthSession {
        guard let session = currentSession, let refreshToken = session.refreshToken else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: config.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "client_id": config.clientId,
            "refresh_token": refreshToken
        ]
        request.httpBody = body.percentEncoded()

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.refreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        let newSession = try await createSession(from: tokenResponse)
        currentSession = newSession
        return newSession
    }

    func logout() async throws {
        currentSession = nil
        // Optionally call logout endpoint
    }

    func supports(credentialType: AuthCredentials.Type) -> Bool {
        credentialType == OAuthCodeCredentials.self
    }

    // MARK: - Private Methods

    private func exchangeCodeForTokens(code: String, codeVerifier: String?, redirectUri: String) async throws -> AuthSession {
        var request = URLRequest(url: URL(string: config.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = [
            "grant_type": "authorization_code",
            "client_id": config.clientId,
            "code": code,
            "redirect_uri": redirectUri
        ]

        if let verifier = codeVerifier {
            body["code_verifier"] = verifier
        }

        request.httpBody = body.percentEncoded()

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidCredentials
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        let session = try await createSession(from: tokenResponse)
        currentSession = session
        return session
    }

    private func createSession(from tokenResponse: OAuthTokenResponse) async throws -> AuthSession {
        // Decode user info from ID token or call userinfo endpoint
        let user = try decodeUserFromIdToken(tokenResponse.idToken) ?? AuthUser(
            id: UUID().uuidString,
            email: "unknown@unknown.com",
            displayName: "Unknown User",
            departmentId: nil,
            roles: [],
            avatarUrl: nil
        )

        return AuthSession(
            userId: user.id,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
            user: user
        )
    }

    private func decodeUserFromIdToken(_ idToken: String?) throws -> AuthUser? {
        guard let idToken = idToken else { return nil }

        // Decode JWT payload (middle part)
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var payload = String(parts[1])
        // Add padding if needed
        while payload.count % 4 != 0 {
            payload += "="
        }

        guard let data = Data(base64Encoded: payload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")) else {
            return nil
        }

        let claims = try JSONDecoder().decode(OAuthClaims.self, from: data)

        return AuthUser(
            id: claims.sub,
            email: claims.email ?? claims.preferredUsername ?? "\(claims.sub)@unknown.com",
            displayName: claims.name ?? claims.preferredUsername ?? "User",
            departmentId: claims.departmentId,
            roles: claims.roles ?? [],
            avatarUrl: claims.picture
        )
    }

    @MainActor
    private func presentAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: URL(string: config.redirectUri)?.scheme
            ) { callbackUrl, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.userCancelled)
                } else if let error = error {
                    continuation.resume(throwing: AuthError.unknown(error.localizedDescription))
                } else if let callbackUrl = callbackUrl {
                    continuation.resume(returning: callbackUrl)
                } else {
                    continuation.resume(throwing: AuthError.unknown("No callback URL received"))
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    private func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

// MARK: - OAuth Response Models

private struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

private struct OAuthClaims: Codable {
    let sub: String
    let email: String?
    let name: String?
    let preferredUsername: String?
    let picture: String?
    let roles: [String]?
    let departmentId: String?

    enum CodingKeys: String, CodingKey {
        case sub
        case email
        case name
        case preferredUsername = "preferred_username"
        case picture
        case roles
        case departmentId = "department_id"
    }
}

// MARK: - Dictionary Extension

private extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data {
        map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8) ?? Data()
    }
}

// Import CommonCrypto for SHA256
import CommonCrypto
