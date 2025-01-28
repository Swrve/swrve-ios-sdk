import Foundation
import XCTest

@objc public class MockSwrveRESTClient: SwrveRESTClient {
    @objc public var mockData: Data?
    @objc public var mockError: Error?
    @objc public var mockedStatusCode: NSNumber?

    @objc public var lastURLTriggered: URL?
    @objc public var lastRequestTriggered: URLRequest?

    @objc override public func sendHttpRequest(
        _ request: NSMutableURLRequest, completionHandler handler: @escaping (URLResponse?, Data?, Error?) -> Void
    ) {
        lastRequestTriggered = request as URLRequest

        if let statusCode = mockedStatusCode, statusCode.intValue != 200 {
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: statusCode.intValue, httpVersion: nil, headerFields: nil)!
            let error = NSError(domain: "Error", code: -1, userInfo: nil)
            handler(httpResponse, mockData, error)
            return
        }

        if let error = mockError {
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            handler(httpResponse, nil, error)
            return
        }

        let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        handler(httpResponse, mockData, nil)
    }

    @objc override public func sendHttpGETRequest(_ url: URL, queryString query: String?) {
        lastURLTriggered = url
        let fullURL = URL(string: query ?? "", relativeTo: url) ?? url
        sendHttpGETRequest(fullURL, completionHandler: nil)
    }

    @objc override public func sendHttpGETRequest(_ url: URL!, completionHandler handler: ((URLResponse?, Data?, Error?) -> Void)!) {
        lastURLTriggered = url

        if let statusCode = mockedStatusCode, statusCode.intValue != 200 {
            let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.intValue, httpVersion: nil, headerFields: nil)!
            let error = NSError(domain: "Error", code: -1, userInfo: nil)
            handler?(httpResponse, mockData, error)
            return
        }

        if let error = mockError {
            let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            handler?(httpResponse, nil, error)
            return
        }

        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        handler?(httpResponse, mockData, nil)
    }

    @objc override public func sendHttpGETRequest(
        _ baseUrl: URL!, queryString query: String!, completionHandler handler: ((URLResponse?, Data?, Error?) -> Void)!
    ) {
        let fullURL = URL(string: query, relativeTo: baseUrl) ?? baseUrl
        sendHttpGETRequest(fullURL, completionHandler: handler)
    }

    @objc override public func sendHttpPOSTRequest(_ url: URL, jsonData: Data) {
        sendHttpPOSTRequest(url, jsonData: jsonData, completionHandler: nil)
    }

    @objc override public func sendHttpPOSTRequest(
        _ url: URL!, jsonData json: Data!, completionHandler handler: ((URLResponse?, Data?, Error?) -> Void)!
    ) {
        lastURLTriggered = url

        if let statusCode = mockedStatusCode, statusCode.intValue != 200 {
            let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.intValue, httpVersion: nil, headerFields: nil)!
            let error = NSError(domain: "Error", code: -1, userInfo: nil)
            handler?(httpResponse, mockData, error)
            return
        }

        if let error = mockError {
            let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            handler?(httpResponse, nil, error)
            return
        }

        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        handler?(httpResponse, mockData, nil)
    }
}

// Example test how to verify JSON object
// in the same way JSONObject could converted to model using codable API
// and further can be validated against model property
@objc class SwrveRESTClientTests: XCTestCase {
    var mockClient: MockSwrveRESTClient!

    override func setUp() {
        super.setUp()
        mockClient = MockSwrveRESTClient(timeoutInterval: 5.0)
    }

    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }

    @objc func test_sendHttpGETRequest_withValidData() {
        guard let url1 = Bundle.main.url(forResource: "campaignsNone", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url1)
        else {
            XCTFail("Failed to load JSON data")
            return
        }

        mockClient.mockData = jsonData

        let url = URL(string: "https://api.example.com/user")!

        let expectation = self.expectation(description: "Completion handler invoked")

        mockClient.sendHttpGETRequest(url) { (response, data, error) in
            XCTAssertNil(error, "Expected no error")
            XCTAssertNotNil(data, "Expected data to be returned")
            let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
            XCTAssertEqual(jsonData?["version"] as? Int, 2)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    @objc func test_sendHttpGETRequest_withError() {
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
        mockClient.mockError = expectedError

        let url = URL(string: "https://api.example.com/user")!

        let expectation = self.expectation(description: "Completion handler invoked")

        mockClient.sendHttpGETRequest(url) { (response, data, error) in
            XCTAssertNotNil(error, "Expected an error")
            XCTAssertNil(data, "Expected no data")
            XCTAssertEqual((error as NSError?)?.domain, expectedError.domain, "Error domain should match")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
