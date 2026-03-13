import Foundation

// MARK: - Auth Provider Factory

/// Factory for creating the appropriate AuthProvider based on configuration.
enum AuthProviderFactory {

    /// Create an auth provider from the given configuration
    static func create(from config: AuthConfig) -> AuthProvider {
        switch config.providerType {
        case .oauth:
            guard let oauthConfig = config.oauth else {
                fatalError("OAuth config required for oauth provider type")
            }
            return OAuthProvider(config: oauthConfig)

        case .saml:
            // TODO: Implement SAML provider
            fatalError("SAML provider not yet implemented")

        case .ldap:
            // TODO: Implement LDAP provider
            fatalError("LDAP provider not yet implemented")

        case .basic:
            // TODO: Implement Basic auth provider
            fatalError("Basic auth provider not yet implemented")

        case .mock:
            return MockAuthProvider()
        }
    }

    /// Create a mock provider for testing
    static func createMock() -> MockAuthProvider {
        MockAuthProvider()
    }

    /// Create a provider from a JSON configuration file
    static func create(fromFile filename: String = "auth-config") -> AuthProvider {
        if let config = AuthConfig.load(from: filename) {
            return create(from: config)
        }
        // Fall back to mock if no config file
        print("⚠️ No auth config found, using mock provider")
        return MockAuthProvider()
    }
}
