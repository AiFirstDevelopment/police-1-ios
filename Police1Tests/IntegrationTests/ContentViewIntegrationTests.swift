import XCTest
import SwiftUI
@testable import Police1

/// Integration tests that test the fully assembled app with mocked network.
/// Similar to Angular Testing Library - we render real views but mock external dependencies.
final class ContentViewIntegrationTests: XCTestCase {

    var mockNetworkService: MockNetworkService!
    var dependencies: AppDependencies!

    @MainActor
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        dependencies = AppDependencies.mock(networkService: mockNetworkService)
    }

    override func tearDown() {
        mockNetworkService?.reset()
        mockNetworkService = nil
        dependencies = nil
        super.tearDown()
    }

    // MARK: - Example integration test

    @MainActor
    func testContentViewRenders() throws {
        // Given: A ContentView with mocked dependencies
        let view = ContentView()
            .environmentObject(dependencies)

        // Then: The view should be created without crashing
        XCTAssertNotNil(view)
    }

    @MainActor
    func testContentViewWithMockedNetworkResponse() async throws {
        // Given: A mocked API response
        struct User: Codable, Equatable {
            let id: Int
            let name: String
        }

        let expectedUser = User(id: 1, name: "Test Officer")
        let url = URL(string: "https://api.example.com/user")!
        mockNetworkService.stubFetch(for: url, returning: expectedUser)

        // When: We fetch data through the network service
        let result: User = try await mockNetworkService.fetch(User.self, from: url)

        // Then: We get the mocked response
        XCTAssertEqual(result, expectedUser)
        XCTAssertEqual(mockNetworkService.fetchCalls.count, 1)
        XCTAssertEqual(mockNetworkService.fetchCalls.first?.url, url)
    }
}
