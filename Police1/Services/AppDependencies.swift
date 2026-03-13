import Foundation

// MARK: - Dependency container for the app
@MainActor
final class AppDependencies: ObservableObject {
    let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // Factory for testing with mocked dependencies
    static func mock(networkService: NetworkServiceProtocol) -> AppDependencies {
        AppDependencies(networkService: networkService)
    }
}
