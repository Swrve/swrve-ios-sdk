import XCTest

extension XCTestCase {

    func getMockDataAsRawData(fileName: String) throws -> Data {
        // Prepare mock data
        let path = Bundle.main.url(forResource: fileName, withExtension: "json")!
        let mockedData = try Data(contentsOf: path, options: .mappedIfSafe)
        return mockedData
    }

    func getMockDataAsDictionary(fileName: String) throws -> Dictionary<String, Any>? {
        let mockedData = try getMockDataAsRawData(fileName: fileName)
        let jsonDict = try JSONSerialization.jsonObject(with: mockedData, options: .mutableContainers)
        return jsonDict as? Dictionary<String, Any>
    }

    func mockedResClient(fileName: String) throws -> MockSwrveRESTClient? {
        let mockedData = try getMockDataAsRawData(fileName: fileName)
        let restClient = MockSwrveRESTClient(timeoutInterval: 60.0)
        restClient?.mockData = mockedData
        return restClient
    }

}

@objc extension XCTestCase {

    @objc public func mockedResClientWithSuccessResponse(dataString: String) -> MockSwrveRESTClient {
        let restClient = MockSwrveRESTClient(timeoutInterval: 60.0)
        restClient?.mockData = dataString.data(using: .utf8)
        return restClient!
    }

}
