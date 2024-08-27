@objc public protocol SwrvePushInboxDelegate {
    @objc func onComplete(_ messageId: UInt64, result: SwrvePushInboxResult)
}
