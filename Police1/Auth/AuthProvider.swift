import Foundation

// MARK: - Auth Provider Protocol

/// Protocol that all authentication providers must implement.
/// This allows the app to work with any auth system (OAuth, SAML, LDAP, etc.)
protocol AuthProvider: AnyObject {
    /// The current auth session, if authenticated
    var currentSession: AuthSession? { get }

    /// Authenticate with the given credentials
    func login(with credentials: AuthCredentials) async throws -> AuthSession

    /// Authenticate using the provider's native UI (e.g., OAuth web flow)
    func loginWithUI() async throws -> AuthSession

    /// Refresh the current session's tokens
    func refreshSession() async throws -> AuthSession

    /// Log out and clear the session
    func logout() async throws

    /// Check if the provider supports the given credential type
    func supports(credentialType: AuthCredentials.Type) -> Bool

    /// Provider display name for UI
    var displayName: String { get }

    /// Whether this provider uses external UI for login (e.g., OAuth web view)
    var usesExternalLoginUI: Bool { get }
}

// MARK: - Default Implementations

extension AuthProvider {
    func supports(credentialType: AuthCredentials.Type) -> Bool {
        return credentialType == PasswordCredentials.self
    }

    var usesExternalLoginUI: Bool {
        return false
    }

    func loginWithUI() async throws -> AuthSession {
        throw AuthError.configurationError("This provider does not support UI-based login")
    }
}

// MARK: - Auth Provider Type

/// Enum representing supported auth provider types for configuration
enum AuthProviderType: String, Codable {
    case oauth
    case saml
    case ldap
    case basic
    case mock
}
