/// Represents the result of an operation related to Swrve push inbox listener.
///
/// This class contains the result code, an error message, and the HTTP response code associated with the operation.
@objc public class SwrvePushInboxResult: NSObject {

    /// Initializes a new instance of `SwrvePushInboxResult` with the given parameters.
    /// - Parameters:
    ///   - resultCode: The result code of the operation.
    ///   - errorMessage: The error message associated with the operation, if any.
    ///   - httpResponseCode: The HTTP response code from the operation.
    @objc public init(_ resultCode: SwrvePushInboxResultCode, _ errorMessage: String, _ httpResponseCode: Int) {
        self.resultCode = resultCode
        self.errorMessage = errorMessage
        self.httpResponseCode = httpResponseCode
        super.init()
    }

    /// Result code indicating the outcome of the operation.
    @objc public let resultCode: SwrvePushInboxResultCode

    /// Error message providing additional details in case of failure.
    @objc public let errorMessage: String

    /// HTTP response code associated with the operation, if applicable.
    @objc public let httpResponseCode: Int
}
