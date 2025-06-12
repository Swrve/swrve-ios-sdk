/// Defines a delegate protocol for handling the completion of refreshContent API in Swrve.
@objc public protocol SwrveRefreshContentDelegate {
    /// Called when an operation to refreshContent API is completed.
    /// - Parameter result: The result of the refreshContent operation, which can be either success or failure.
    @objc func onComplete(_ result: SwrveRefreshContentResult)
}
