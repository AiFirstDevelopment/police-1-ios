import Foundation
import SwiftUI
import LocalAuthentication

// MARK: - Auth Manager

/// Main authentication manager that the app uses.
/// Wraps an AuthProvider and provides observable state for SwiftUI.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var state: AuthState = .unknown
    @Published private(set) var isLoading = false
    @Published private(set) var mfaPending: MFAPendingState?

    private var provider: AuthProvider
    private let sessionStorage: SessionStorage
    private(set) var config: AuthConfig

    var currentSession: AuthSession? {
        state.session
    }

    var isAuthenticated: Bool {
        state.isAuthenticated
    }

    var currentUser: AuthUser? {
        currentSession?.user
    }

    var isMFARequired: Bool {
        config.mfa?.required ?? false
    }

    var availableMFAMethods: [MFAMethodType] {
        config.mfa?.methods ?? []
    }

    var loginIdentifiers: [LoginIdentifierType] {
        config.loginIdentifiers
    }

    var primaryIdentifier: LoginIdentifierType {
        config.primaryIdentifier
    }

    init(
        provider: AuthProvider,
        config: AuthConfig = .mock,
        sessionStorage: SessionStorage = KeychainSessionStorage()
    ) {
        self.provider = provider
        self.config = config
        self.sessionStorage = sessionStorage
    }

    // For backwards compatibility
    convenience init(provider: AuthProvider, sessionStorage: SessionStorage) {
        self.init(provider: provider, config: .mock, sessionStorage: sessionStorage)
    }

    // MARK: - Public Methods

    /// Reconfigure the auth manager with a new provider and config.
    /// Used after enrollment when switching to a department-specific auth provider.
    func reconfigure(with newProvider: AuthProvider, config newConfig: AuthConfig) async {
        self.provider = newProvider
        self.config = newConfig
        self.state = .unknown
        self.mfaPending = nil
    }

    /// Initialize auth state by checking for existing session
    func initialize() async {
        if let session = sessionStorage.load() {
            if session.isExpired {
                // Try to refresh
                do {
                    let newSession = try await provider.refreshSession()
                    sessionStorage.save(newSession)
                    state = .authenticated(newSession)
                } catch {
                    sessionStorage.clear()
                    state = .unauthenticated
                }
            } else {
                state = .authenticated(session)
            }
        } else {
            state = .unauthenticated
        }
    }

    /// Login with credentials (username/password) - legacy support
    func login(username: String, password: String) async {
        await login(with: PasswordCredentials(username: username, password: password))
    }

    /// Login with flexible identifier (badge number, email, phone, etc.)
    func login(identifier: String, password: String, identifierType: LoginIdentifierType) async {
        await login(with: IdentifierCredentials(
            identifierType: identifierType,
            identifier: identifier,
            password: password
        ))
    }

    /// Login with any credential type
    func login(with credentials: AuthCredentials) async {
        guard !isLoading else { return }

        isLoading = true
        state = .authenticating

        do {
            let session = try await provider.login(with: credentials)
            sessionStorage.save(session)
            state = .authenticated(session)
        } catch let error as AuthError {
            state = .error(error)
        } catch {
            state = .error(.unknown(error.localizedDescription))
        }

        isLoading = false
    }

    /// Login using provider's native UI (OAuth, etc.)
    func loginWithUI() async {
        guard !isLoading else { return }
        guard provider.usesExternalLoginUI else {
            state = .error(.configurationError("Provider does not support UI login"))
            return
        }

        isLoading = true
        state = .authenticating

        do {
            let session = try await provider.loginWithUI()
            sessionStorage.save(session)
            state = .authenticated(session)
        } catch let error as AuthError {
            state = .error(error)
        } catch {
            state = .error(.unknown(error.localizedDescription))
        }

        isLoading = false
    }

    /// Logout
    func logout() async {
        isLoading = true

        do {
            try await provider.logout()
        } catch {
            // Continue with local logout even if remote fails
        }

        sessionStorage.clear()
        state = .unauthenticated
        isLoading = false
    }

    /// Refresh the current session
    func refreshIfNeeded() async {
        guard let session = currentSession, session.isExpiringSoon else { return }

        do {
            let newSession = try await provider.refreshSession()
            sessionStorage.save(newSession)
            state = .authenticated(newSession)
        } catch {
            // Session refresh failed, will need to re-login
            sessionStorage.clear()
            state = .unauthenticated
        }
    }

    /// Clear any error state
    func clearError() {
        if case .error = state {
            state = .unauthenticated
        }
    }

    /// Provider info
    var providerDisplayName: String {
        provider.displayName
    }

    var usesExternalLoginUI: Bool {
        provider.usesExternalLoginUI
    }

    // MARK: - MFA Methods

    /// Verify MFA using biometrics (Face ID / Touch ID)
    func verifyWithBiometric() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to continue"
            )

            if success, let pending = mfaPending {
                // Complete MFA verification
                await completeMFAVerification(sessionToken: pending.sessionToken, method: .biometric)
            }

            return success
        } catch {
            return false
        }
    }

    /// Verify MFA using OTP code
    func verifyWithOTP(code: String) async {
        guard let pending = mfaPending else { return }

        isLoading = true
        // In a real implementation, this would validate the OTP with the server
        // For mock, we accept "123456" as valid
        if code == "123456" || code.count == 6 {
            await completeMFAVerification(sessionToken: pending.sessionToken, method: .otp)
        } else {
            state = .error(.invalidCredentials)
        }
        isLoading = false
    }

    /// Cancel pending MFA
    func cancelMFA() {
        mfaPending = nil
        state = .unauthenticated
    }

    private func completeMFAVerification(sessionToken: String, method: MFAMethodType) async {
        guard let pending = mfaPending else { return }

        // In real implementation, exchange MFA verification for final session
        // For mock, just use the pending session
        sessionStorage.save(pending.partialSession)
        state = .authenticated(pending.partialSession)
        mfaPending = nil
    }

    /// Check if device supports biometric auth
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .none
        }
    }
}

// MARK: - MFA Pending State

struct MFAPendingState {
    let sessionToken: String
    let availableMethods: [MFAMethodType]
    let partialSession: AuthSession
}

// MARK: - Biometric Type

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID

    var displayName: String {
        switch self {
        case .none: return "Biometric"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }

    var icon: String {
        switch self {
        case .none, .touchID: return "touchid"
        case .faceID: return "faceid"
        case .opticID: return "opticid"
        }
    }
}

// MARK: - Session Storage Protocol

protocol SessionStorage {
    func save(_ session: AuthSession)
    func load() -> AuthSession?
    func clear()
}

// MARK: - Keychain Session Storage

final class KeychainSessionStorage: SessionStorage {
    private let key = "com.police1.authSession"

    func save(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func load() -> AuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let session = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            return nil
        }

        return session
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - In-Memory Session Storage (for testing)

final class InMemorySessionStorage: SessionStorage {
    private var session: AuthSession?

    func save(_ session: AuthSession) {
        self.session = session
    }

    func load() -> AuthSession? {
        session
    }

    func clear() {
        session = nil
    }
}
