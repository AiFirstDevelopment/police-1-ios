import Foundation

// MARK: - Dependency container for the app
@MainActor
final class AppDependencies: ObservableObject {
    let networkService: NetworkServiceProtocol
    let authManager: AuthManager

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        authProvider: AuthProvider? = nil,
        authConfig: AuthConfig? = nil,
        sessionStorage: SessionStorage = KeychainSessionStorage()
    ) {
        self.networkService = networkService

        // Load config from file or use provided/default
        let config = authConfig ?? AuthConfig.load(from: "auth-config") ?? .mock

        // Create auth provider from config or use provided one
        let provider = authProvider ?? AuthProviderFactory.create(from: config)
        self.authManager = AuthManager(provider: provider, config: config, sessionStorage: sessionStorage)
    }

    // Factory for testing with mocked dependencies
    static func mock(
        networkService: NetworkServiceProtocol = NetworkService(),
        authProvider: AuthProvider = MockAuthProvider()
    ) -> AppDependencies {
        AppDependencies(
            networkService: networkService,
            authProvider: authProvider,
            sessionStorage: InMemorySessionStorage()
        )
    }
}
