import Foundation

// MARK: - Login Identifier Types

/// Supported login identifier types that departments can configure
enum LoginIdentifierType: String, Codable, CaseIterable {
    case email
    case username
    case badgeNumber
    case employeeId
    case phoneNumber

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .username: return "Username"
        case .badgeNumber: return "Badge Number"
        case .employeeId: return "Employee ID"
        case .phoneNumber: return "Phone Number"
        }
    }

    var placeholder: String {
        switch self {
        case .email: return "officer@department.gov"
        case .username: return "jsmith"
        case .badgeNumber: return "12345"
        case .employeeId: return "EMP-001"
        case .phoneNumber: return "(555) 123-4567"
        }
    }

    var icon: String {
        switch self {
        case .email: return "envelope"
        case .username: return "person"
        case .badgeNumber: return "shield"
        case .employeeId: return "person.text.rectangle"
        case .phoneNumber: return "phone"
        }
    }

    var keyboardType: KeyboardType {
        switch self {
        case .email: return .email
        case .phoneNumber: return .phone
        case .badgeNumber, .employeeId: return .numbersAndPunctuation
        case .username: return .default
        }
    }

    enum KeyboardType {
        case email, phone, numbersAndPunctuation, `default`
    }
}

// MARK: - MFA Method Types

/// Supported MFA methods
enum MFAMethodType: String, Codable, CaseIterable {
    case biometric      // Face ID / Touch ID
    case otp            // One-time password (SMS/Email/Authenticator)
    case hardwareToken  // Physical security key
    case pushNotification // Push to approved device
    case smartCard      // CAC/PIV card

    var displayName: String {
        switch self {
        case .biometric: return "Biometric (Face ID / Touch ID)"
        case .otp: return "One-Time Password"
        case .hardwareToken: return "Security Key"
        case .pushNotification: return "Push Notification"
        case .smartCard: return "Smart Card (CAC/PIV)"
        }
    }

    var icon: String {
        switch self {
        case .biometric: return "faceid"
        case .otp: return "key"
        case .hardwareToken: return "cpu"
        case .pushNotification: return "bell.badge"
        case .smartCard: return "creditcard"
        }
    }
}

// MARK: - Auth Session

/// Represents an authenticated user session
struct AuthSession: Codable, Equatable {
    let userId: String
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let user: AuthUser

    var isExpired: Bool {
        Date() >= expiresAt
    }

    var isExpiringSoon: Bool {
        Date().addingTimeInterval(300) >= expiresAt // 5 minutes
    }
}

// MARK: - Auth User

/// Represents the authenticated user's profile
struct AuthUser: Codable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let departmentId: String?
    let roles: [String]
    let avatarUrl: String?

    var initials: String {
        let components = displayName.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Auth Credentials

/// Base protocol for authentication credentials
protocol AuthCredentials {}

/// Flexible identifier + password credentials
/// Supports any login identifier type (email, badge, phone, etc.)
struct IdentifierCredentials: AuthCredentials {
    let identifierType: LoginIdentifierType
    let identifier: String
    let password: String
}

/// Username/password credentials (legacy support)
struct PasswordCredentials: AuthCredentials {
    let username: String
    let password: String
}

/// MFA verification credentials
struct MFACredentials: AuthCredentials {
    let method: MFAMethodType
    let code: String?           // For OTP
    let biometricToken: Data?   // For biometric verification result
    let sessionToken: String    // Links to pending auth session
}

/// OAuth authorization code credentials
struct OAuthCodeCredentials: AuthCredentials {
    let authorizationCode: String
    let codeVerifier: String?
    let redirectUri: String
}

/// SSO/SAML assertion credentials
struct SAMLCredentials: AuthCredentials {
    let assertion: String
    let relayState: String?
}

// MARK: - Auth Errors

enum AuthError: Error, Equatable {
    case invalidCredentials
    case sessionExpired
    case refreshFailed
    case networkError(String)
    case configurationError(String)
    case userCancelled
    case notAuthenticated
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .refreshFailed:
            return "Failed to refresh authentication. Please log in again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .userCancelled:
            return "Authentication was cancelled"
        case .notAuthenticated:
            return "You are not logged in"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Auth State

/// Observable auth state for the UI
enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticating
    case authenticated(AuthSession)
    case error(AuthError)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    var session: AuthSession? {
        if case .authenticated(let session) = self { return session }
        return nil
    }
}
