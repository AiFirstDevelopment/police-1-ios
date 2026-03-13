import Foundation

// MARK: - Mock Auth Provider

/// Mock authentication provider for development and testing.
/// Simulates authentication without hitting real servers.
final class MockAuthProvider: AuthProvider {
    var currentSession: AuthSession?

    let displayName = "Development Mode"
    let usesExternalLoginUI = false

    // Configuration for testing
    var simulatedDelay: TimeInterval = 1.0
    var shouldFailLogin = false
    var shouldFailRefresh = false
    var failureError: AuthError = .invalidCredentials

    // Test accounts by various identifier types
    private let testAccountsByEmail: [String: String] = [
        "officer@pd.local": "password123",
        "admin@pd.local": "admin123",
        "test@test.com": "test"
    ]

    private let testAccountsByBadge: [String: (password: String, email: String)] = [
        "12345": (password: "password123", email: "officer@pd.local"),
        "99999": (password: "admin123", email: "admin@pd.local"),
        "00001": (password: "test", email: "test@test.com")
    ]

    private let testAccountsByEmployeeId: [String: (password: String, email: String)] = [
        "EMP-001": (password: "password123", email: "officer@pd.local"),
        "EMP-999": (password: "admin123", email: "admin@pd.local")
    ]

    private let testAccountsByPhone: [String: (password: String, email: String)] = [
        "5551234567": (password: "password123", email: "officer@pd.local"),
        "5559999999": (password: "admin123", email: "admin@pd.local")
    ]

    func login(with credentials: AuthCredentials) async throws -> AuthSession {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        if shouldFailLogin {
            throw failureError
        }

        // Handle flexible identifier credentials
        if let identifierCreds = credentials as? IdentifierCredentials {
            return try await loginWithIdentifier(identifierCreds)
        }

        // Handle legacy password credentials
        guard let passwordCreds = credentials as? PasswordCredentials else {
            throw AuthError.configurationError("Unsupported credential type")
        }

        // Validate against test accounts
        guard let expectedPassword = testAccountsByEmail[passwordCreds.username.lowercased()],
              expectedPassword == passwordCreds.password else {
            throw AuthError.invalidCredentials
        }

        let session = createSession(for: passwordCreds.username)
        currentSession = session
        return session
    }

    private func loginWithIdentifier(_ credentials: IdentifierCredentials) async throws -> AuthSession {
        let identifier = credentials.identifier
        let password = credentials.password

        var email: String?

        switch credentials.identifierType {
        case .email:
            if testAccountsByEmail[identifier.lowercased()] == password {
                email = identifier
            }

        case .badgeNumber:
            if let account = testAccountsByBadge[identifier],
               account.password == password {
                email = account.email
            }

        case .employeeId:
            if let account = testAccountsByEmployeeId[identifier.uppercased()],
               account.password == password {
                email = account.email
            }

        case .phoneNumber:
            let normalized = identifier.filter { $0.isNumber }
            if let account = testAccountsByPhone[normalized],
               account.password == password {
                email = account.email
            }

        case .username:
            // For username, check email accounts
            if testAccountsByEmail[identifier.lowercased()] == password {
                email = identifier
            }
        }

        guard let validEmail = email else {
            throw AuthError.invalidCredentials
        }

        let session = createSession(for: validEmail)
        currentSession = session
        return session
    }

    func refreshSession() async throws -> AuthSession {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        if shouldFailRefresh {
            currentSession = nil
            throw AuthError.refreshFailed
        }

        guard let current = currentSession else {
            throw AuthError.notAuthenticated
        }

        let newSession = createSession(for: current.user.email)
        currentSession = newSession
        return newSession
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        currentSession = nil
    }

    func supports(credentialType: AuthCredentials.Type) -> Bool {
        credentialType == PasswordCredentials.self
    }

    // MARK: - Helpers

    private func createSession(for email: String) -> AuthSession {
        let user = AuthUser(
            id: UUID().uuidString,
            email: email,
            displayName: displayNameFor(email: email),
            departmentId: "DEPT-001",
            roles: rolesFor(email: email),
            avatarUrl: nil
        )

        return AuthSession(
            userId: user.id,
            accessToken: "mock-access-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour
            user: user
        )
    }

    private func displayNameFor(email: String) -> String {
        switch email.lowercased() {
        case "officer@pd.local":
            return "Officer Smith"
        case "admin@pd.local":
            return "Admin Johnson"
        default:
            return "Test User"
        }
    }

    private func rolesFor(email: String) -> [String] {
        switch email.lowercased() {
        case "admin@pd.local":
            return ["admin", "officer"]
        case "officer@pd.local":
            return ["officer"]
        default:
            return ["user"]
        }
    }
}

// MARK: - Mock Provider Factory Extension

extension MockAuthProvider {
    /// Create a provider that always succeeds instantly (for UI previews)
    static var instant: MockAuthProvider {
        let provider = MockAuthProvider()
        provider.simulatedDelay = 0
        return provider
    }

    /// Create a provider that always fails
    static func failing(with error: AuthError = .invalidCredentials) -> MockAuthProvider {
        let provider = MockAuthProvider()
        provider.shouldFailLogin = true
        provider.failureError = error
        return provider
    }
}
