import Foundation
@testable import Police1

/// Mock network service for unit testing without URLSession
final class MockNetworkService: NetworkServiceProtocol {

    // MARK: - Recorded calls for verification
    var fetchCalls: [(type: Any.Type, url: URL)] = []
    var postCalls: [(body: Any, url: URL)] = []

    // MARK: - Stubbed responses
    private var stubbedFetchResponses: [URL: Any] = [:]
    private var stubbedPostResponses: [URL: Any] = [:]
    private var stubbedErrors: [URL: Error] = [:]

    // MARK: - Setup methods
    func stubFetch<T: Decodable>(for url: URL, returning value: T) {
        stubbedFetchResponses[url] = value
    }

    func stubPost<T: Decodable>(for url: URL, returning value: T) {
        stubbedPostResponses[url] = value
    }

    func stubError(for url: URL, error: Error) {
        stubbedErrors[url] = error
    }

    func reset() {
        fetchCalls = []
        postCalls = []
        stubbedFetchResponses = [:]
        stubbedPostResponses = [:]
        stubbedErrors = [:]
    }

    // MARK: - Protocol implementation
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        fetchCalls.append((type: type, url: url))

        if let error = stubbedErrors[url] {
            throw error
        }

        guard let response = stubbedFetchResponses[url] as? T else {
            throw MockNetworkError.noStubbedResponse(url: url)
        }

        return response
    }

    func post<T: Decodable, U: Encodable>(_ body: U, to url: URL) async throws -> T {
        postCalls.append((body: body, url: url))

        if let error = stubbedErrors[url] {
            throw error
        }

        guard let response = stubbedPostResponses[url] as? T else {
            throw MockNetworkError.noStubbedResponse(url: url)
        }

        return response
    }
}

enum MockNetworkError: Error {
    case noStubbedResponse(url: URL)
}
