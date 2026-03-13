import Foundation

/// A URLProtocol subclass that intercepts all network requests for testing.
/// This allows us to return mock responses without hitting real endpoints.
final class MockURLProtocol: URLProtocol {

    /// Handler that determines what response to return for a given request
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler must be set before making requests")
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Required but nothing to do here
    }
}

// MARK: - Test helpers
extension MockURLProtocol {
    /// Creates a URLSession configured to use MockURLProtocol
    static func mockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Sets up a mock response for any request
    static func setMockResponse<T: Encodable>(
        _ body: T,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        requestHandler = { request in
            let data = try JSONEncoder().encode(body)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (response, data)
        }
    }

    /// Sets up a mock response that matches specific URLs
    static func setMockResponses(_ responses: [URL: (Int, Data)]) {
        requestHandler = { request in
            guard let url = request.url,
                  let (statusCode, data) = responses[url] else {
                throw URLError(.fileDoesNotExist)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
    }

    /// Sets up a mock error response
    static func setMockError(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }

    /// Resets the mock handler
    static func reset() {
        requestHandler = nil
    }
}
