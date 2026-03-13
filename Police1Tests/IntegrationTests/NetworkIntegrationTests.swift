import XCTest
@testable import Police1

/// Integration tests using MockURLProtocol to intercept real URLSession requests.
/// This tests the actual NetworkService with mocked HTTP responses.
final class NetworkIntegrationTests: XCTestCase {

    var networkService: NetworkService!

    override func setUp() {
        super.setUp()
        // Create a NetworkService with a session that uses MockURLProtocol
        let mockSession = MockURLProtocol.mockSession()
        networkService = NetworkService(session: mockSession)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        networkService = nil
        super.tearDown()
    }

    // MARK: - Test models

    struct TestResponse: Codable, Equatable {
        let message: String
        let count: Int
    }

    struct TestRequest: Codable {
        let action: String
    }

    // MARK: - Fetch tests

    func testFetchSuccess() async throws {
        // Given: A mock response
        let expected = TestResponse(message: "Success", count: 42)
        MockURLProtocol.setMockResponse(expected)

        let url = URL(string: "https://api.example.com/data")!

        // When: We fetch data
        let result: TestResponse = try await networkService.fetch(TestResponse.self, from: url)

        // Then: We get the expected response
        XCTAssertEqual(result, expected)
    }

    func testFetchFailsWithServerError() async {
        // Given: A 500 error response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let url = URL(string: "https://api.example.com/data")!

        // When/Then: Fetch should throw an error
        do {
            let _: TestResponse = try await networkService.fetch(TestResponse.self, from: url)
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpError(statusCode: 500))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchFailsWithNetworkError() async {
        // Given: A network error
        MockURLProtocol.setMockError(URLError(.notConnectedToInternet))

        let url = URL(string: "https://api.example.com/data")!

        // When/Then: Fetch should throw an error
        do {
            let _: TestResponse = try await networkService.fetch(TestResponse.self, from: url)
            XCTFail("Expected error to be thrown")
        } catch is URLError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - POST tests

    func testPostSuccess() async throws {
        // Given: A mock response and request
        let expected = TestResponse(message: "Created", count: 1)
        MockURLProtocol.setMockResponse(expected)

        let url = URL(string: "https://api.example.com/action")!
        let requestBody = TestRequest(action: "create")

        // When: We post data
        let result: TestResponse = try await networkService.post(requestBody, to: url)

        // Then: We get the expected response
        XCTAssertEqual(result, expected)
    }

    func testPostSendsCorrectBody() async throws {
        // Given: A handler that captures the request body
        var capturedBody: Data?
        var capturedContentType: String?
        MockURLProtocol.requestHandler = { request in
            // httpBody may be nil when using URLSession - read from httpBodyStream if needed
            if let body = request.httpBody {
                capturedBody = body
            } else if let stream = request.httpBodyStream {
                stream.open()
                var data = Data()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let bytesRead = stream.read(buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        data.append(buffer, count: bytesRead)
                    }
                }
                stream.close()
                capturedBody = data
            }
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let responseData = try! JSONEncoder().encode(TestResponse(message: "OK", count: 0))
            return (response, responseData)
        }

        let url = URL(string: "https://api.example.com/action")!
        let requestBody = TestRequest(action: "test_action")

        // When: We post data
        let _: TestResponse = try await networkService.post(requestBody, to: url)

        // Then: The request body was sent correctly
        XCTAssertNotNil(capturedBody, "Request body should not be nil")
        XCTAssertEqual(capturedContentType, "application/json")

        let decoded = try JSONDecoder().decode(TestRequest.self, from: capturedBody!)
        XCTAssertEqual(decoded.action, "test_action")
    }
}
