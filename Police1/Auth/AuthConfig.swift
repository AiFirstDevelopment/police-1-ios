import Foundation

// MARK: - Auth Configuration

/// Configuration for the authentication system.
/// This can be loaded from a JSON file, remote config, or MDM profile.
struct AuthConfig: Codable {
    let providerType: AuthProviderType

    /// Which login identifiers are accepted (e.g., badge number, email)
    let loginIdentifiers: [LoginIdentifierType]

    /// MFA configuration
    let mfa: MFAConfig?

    /// Provider-specific configurations
    let oauth: OAuthConfig?
    let saml: SAMLConfig?
    let ldap: LDAPConfig?
    let basic: BasicAuthConfig?

    /// Department branding
    let branding: BrandingConfig?

    /// Load config from a JSON file in the bundle
    static func load(from filename: String = "auth-config") -> AuthConfig? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(AuthConfig.self, from: data) else {
            return nil
        }
        return config
    }

    /// Default mock configuration for development/testing
    static var mock: AuthConfig {
        AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.email, .badgeNumber],
            mfa: MFAConfig(
                required: false,
                methods: [.biometric, .otp],
                graceperiodDays: 7,
                rememberDeviceDays: 30
            ),
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
    }

    /// Primary login identifier (first in list)
    var primaryIdentifier: LoginIdentifierType {
        loginIdentifiers.first ?? .email
    }
}

// MARK: - MFA Configuration

struct MFAConfig: Codable {
    /// Whether MFA is required (should be true for CJIS compliance)
    let required: Bool

    /// Allowed MFA methods
    let methods: [MFAMethodType]

    /// Days before MFA setup is enforced for new users
    let graceperiodDays: Int?

    /// Whether to remember device for a period
    let rememberDeviceDays: Int?

    /// Default MFA config for CJIS compliance
    static var cjisCompliant: MFAConfig {
        MFAConfig(
            required: true,
            methods: [.biometric, .otp, .pushNotification],
            graceperiodDays: 0,
            rememberDeviceDays: nil
        )
    }
}

// MARK: - Branding Configuration

struct BrandingConfig: Codable {
    let departmentName: String?
    let logoUrl: String?
    let primaryColor: String?  // Hex color
    let supportEmail: String?
    let supportPhone: String?
}

// MARK: - OAuth Configuration

struct OAuthConfig: Codable {
    let authority: String          // e.g., "https://login.microsoftonline.com/tenant-id"
    let clientId: String
    let redirectUri: String
    let scopes: [String]
    let usePKCE: Bool

    var authorizationEndpoint: String {
        "\(authority)/oauth2/v2.0/authorize"
    }

    var tokenEndpoint: String {
        "\(authority)/oauth2/v2.0/token"
    }

    var logoutEndpoint: String {
        "\(authority)/oauth2/v2.0/logout"
    }
}

// MARK: - SAML Configuration

struct SAMLConfig: Codable {
    let identityProviderUrl: String
    let entityId: String
    let assertionConsumerServiceUrl: String
    let certificate: String?
}

// MARK: - LDAP Configuration

struct LDAPConfig: Codable {
    let serverUrl: String
    let baseDN: String
    let userSearchFilter: String
    let bindDN: String?
    let useTLS: Bool
}

// MARK: - Basic Auth Configuration

struct BasicAuthConfig: Codable {
    let apiBaseUrl: String
    let loginEndpoint: String
    let refreshEndpoint: String
    let logoutEndpoint: String
}
