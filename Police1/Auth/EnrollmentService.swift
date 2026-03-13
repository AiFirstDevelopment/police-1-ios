import Foundation

// MARK: - Enrollment Service

/// Service for discovering and fetching organization configuration.
/// Handles the initial app setup when an officer first downloads the app.
final class EnrollmentService: ObservableObject {

    private let urlSession: URLSession
    private let configStorage: ConfigStorage

    /// Base URL for the config discovery service
    /// In production, this would be your central config server
    private let discoveryBaseUrl = "https://config.police1app.com/api/v1"

    init(urlSession: URLSession = .shared, configStorage: ConfigStorage = UserDefaultsConfigStorage()) {
        self.urlSession = urlSession
        self.configStorage = configStorage
    }

    // MARK: - Enrollment Methods

    /// Enroll using an organization code (e.g., "SPRINGFIELD-PD")
    func enrollWithCode(_ code: String) async throws -> AuthConfig {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // In production: fetch from server
        // let url = URL(string: "\(discoveryBaseUrl)/orgs/\(normalizedCode)/config")!
        // let config = try await fetchConfig(from: url)

        // For demo: use mock configs
        let config = try mockConfigForCode(normalizedCode)
        configStorage.save(config)
        return config
    }

    /// Enroll by detecting organization from email domain
    func enrollWithEmail(_ email: String) async throws -> AuthConfig {
        guard let domain = email.split(separator: "@").last else {
            throw EnrollmentError.invalidEmail
        }

        let normalizedDomain = String(domain).lowercased()

        // In production: fetch from server
        // let url = URL(string: "\(discoveryBaseUrl)/domains/\(normalizedDomain)/config")!
        // let config = try await fetchConfig(from: url)

        // For demo: use mock configs
        let config = try mockConfigForDomain(normalizedDomain)
        configStorage.save(config)
        return config
    }

    /// Enroll by scanning a QR code containing config URL or JSON
    func enrollWithQRCode(_ qrContent: String) async throws -> AuthConfig {
        // QR can contain either:
        // 1. A URL to fetch config from
        // 2. Direct JSON config (base64 encoded)
        // 3. An org code prefixed with "ORG:"

        if qrContent.hasPrefix("ORG:") {
            let code = String(qrContent.dropFirst(4))
            return try await enrollWithCode(code)
        }

        if qrContent.hasPrefix("http") {
            guard let url = URL(string: qrContent) else {
                throw EnrollmentError.invalidQRCode
            }
            let config = try await fetchConfig(from: url)
            configStorage.save(config)
            return config
        }

        // Try to decode as base64 JSON
        if let data = Data(base64Encoded: qrContent),
           let config = try? JSONDecoder().decode(AuthConfig.self, from: data) {
            configStorage.save(config)
            return config
        }

        throw EnrollmentError.invalidQRCode
    }

    /// Enroll via deep link (e.g., police1://enroll?org=SPRINGFIELD)
    func enrollWithDeepLink(_ url: URL) async throws -> AuthConfig {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw EnrollmentError.invalidDeepLink
        }

        // Check for org code in query params
        if let orgCode = components.queryItems?.first(where: { $0.name == "org" })?.value {
            return try await enrollWithCode(orgCode)
        }

        // Check for config URL in query params
        if let configUrl = components.queryItems?.first(where: { $0.name == "config" })?.value,
           let url = URL(string: configUrl) {
            let config = try await fetchConfig(from: url)
            configStorage.save(config)
            return config
        }

        throw EnrollmentError.invalidDeepLink
    }

    // MARK: - Config Management

    /// Check if device is already enrolled
    var isEnrolled: Bool {
        configStorage.load() != nil
    }

    /// Get current config
    var currentConfig: AuthConfig? {
        configStorage.load()
    }

    /// Clear enrollment (for logout/reset)
    func clearEnrollment() {
        configStorage.clear()
    }

    // MARK: - Private Methods

    private func fetchConfig(from url: URL) async throws -> AuthConfig {
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EnrollmentError.configNotFound
        }

        do {
            return try JSONDecoder().decode(AuthConfig.self, from: data)
        } catch {
            throw EnrollmentError.invalidConfig
        }
    }

    // MARK: - Mock Configs for Demo

    private func mockConfigForCode(_ code: String) throws -> AuthConfig {
        switch code {
        case "SPRINGFIELD", "SPRINGFIELD-PD":
            return springfieldConfig

        case "RIVERSIDE", "RIVERSIDE-PD":
            return riversideConfig

        case "METRO", "METRO-PD":
            return metroConfig

        case "DEMO", "TEST":
            return .mock

        default:
            throw EnrollmentError.organizationNotFound
        }
    }

    private func mockConfigForDomain(_ domain: String) throws -> AuthConfig {
        switch domain {
        case "springfield.gov", "springfieldpd.gov":
            return springfieldConfig

        case "riverside.gov", "riversidepd.org":
            return riversideConfig

        case "metro.gov", "metropolice.gov":
            return metroConfig

        case "pd.local", "test.com":
            return .mock

        default:
            throw EnrollmentError.organizationNotFound
        }
    }

    // MARK: - Sample Department Configs

    private var springfieldConfig: AuthConfig {
        AuthConfig(
            providerType: .mock, // Use .oauth in production with real tenant
            loginIdentifiers: [.badgeNumber, .email],
            mfa: MFAConfig(
                required: true,
                methods: [.biometric, .otp],
                graceperiodDays: 0,
                rememberDeviceDays: 7
            ),
            oauth: OAuthConfig(
                authority: "https://login.microsoftonline.com/springfield-pd",
                clientId: "springfield-police1-app",
                redirectUri: "police1://auth",
                scopes: ["openid", "profile", "email"],
                usePKCE: true
            ),
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: BrandingConfig(
                departmentName: "Springfield Police Department",
                logoUrl: nil,
                primaryColor: "#1E40AF",
                supportEmail: "it@springfieldpd.gov",
                supportPhone: "555-123-4567"
            )
        )
    }

    private var riversideConfig: AuthConfig {
        AuthConfig(
            providerType: .mock, // Would be .ldap in production
            loginIdentifiers: [.employeeId, .badgeNumber],
            mfa: MFAConfig(
                required: true,
                methods: [.biometric, .smartCard],
                graceperiodDays: 0,
                rememberDeviceDays: nil
            ),
            oauth: nil,
            saml: nil,
            ldap: LDAPConfig(
                serverUrl: "ldaps://ldap.riversidepd.org",
                baseDN: "ou=officers,dc=riverside,dc=gov",
                userSearchFilter: "(employeeId={0})",
                bindDN: nil,
                useTLS: true
            ),
            basic: nil,
            branding: BrandingConfig(
                departmentName: "Riverside Police Department",
                logoUrl: nil,
                primaryColor: "#059669",
                supportEmail: "support@riversidepd.org",
                supportPhone: "555-987-6543"
            )
        )
    }

    private var metroConfig: AuthConfig {
        AuthConfig(
            providerType: .mock, // Use .saml in production with real IdP
            loginIdentifiers: [.email],
            mfa: MFAConfig(
                required: true,
                methods: [.pushNotification, .hardwareToken],
                graceperiodDays: 0,
                rememberDeviceDays: 30
            ),
            oauth: nil,
            saml: SAMLConfig(
                identityProviderUrl: "https://sso.metro.gov/saml",
                entityId: "police1-metro",
                assertionConsumerServiceUrl: "police1://saml/acs",
                certificate: nil
            ),
            ldap: nil,
            basic: nil,
            branding: BrandingConfig(
                departmentName: "Metropolitan Police",
                logoUrl: nil,
                primaryColor: "#7C3AED",
                supportEmail: "helpdesk@metro.gov",
                supportPhone: "555-456-7890"
            )
        )
    }
}

// MARK: - Enrollment Errors

enum EnrollmentError: Error, LocalizedError, Equatable {
    case invalidEmail
    case invalidQRCode
    case invalidDeepLink
    case invalidConfig
    case configNotFound
    case organizationNotFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidQRCode:
            return "Invalid QR code. Please try again."
        case .invalidDeepLink:
            return "Invalid enrollment link"
        case .invalidConfig:
            return "Unable to read organization configuration"
        case .configNotFound:
            return "Configuration not found"
        case .organizationNotFound:
            return "Organization not found. Check your code and try again."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Config Storage Protocol

protocol ConfigStorage {
    func save(_ config: AuthConfig)
    func load() -> AuthConfig?
    func clear()
}

// MARK: - UserDefaults Config Storage

final class UserDefaultsConfigStorage: ConfigStorage {
    private let key = "com.police1.enrolledConfig"

    func save(_ config: AuthConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() -> AuthConfig? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let config = try? JSONDecoder().decode(AuthConfig.self, from: data) else {
            return nil
        }
        return config
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - In-Memory Config Storage (for testing)

final class InMemoryConfigStorage: ConfigStorage {
    private var config: AuthConfig?

    func save(_ config: AuthConfig) {
        self.config = config
    }

    func load() -> AuthConfig? {
        config
    }

    func clear() {
        config = nil
    }
}
