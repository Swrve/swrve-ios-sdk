import Foundation

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

//TODO - these generally useful extension helper functions should be moved to a home
//in a swift helpers file somewhere central in the sdk/common.
extension Date {
    init(epochMilliseconds: UInt64) {
        self.init(timeIntervalSince1970: TimeInterval(epochMilliseconds / 1000))
    }
}

enum HttpStatus {
    case HTTP_SUCCESS
    case HTTP_REDIRECTION
    case HTTP_CLIENT_ERROR
    case HTTP_CLIENT_ERROR_RETRY
    case HTTP_SERVER_ERROR
}

extension URLResponse {
    var http: HTTPURLResponse? {
        self as? HTTPURLResponse
    }
}

extension HTTPURLResponse {
    var httpStatus: HttpStatus {
        let code = self.statusCode
        if code < 300 { return HttpStatus.HTTP_SUCCESS }
        if code < 400 { return HttpStatus.HTTP_REDIRECTION }
        if code == 429 { return HttpStatus.HTTP_CLIENT_ERROR_RETRY }
        if code < 500 { return HttpStatus.HTTP_CLIENT_ERROR }
        // 500+
        return HttpStatus.HTTP_SERVER_ERROR
    }
}

@objc public class SwrvePushInboxController: NSObject {

    private let STATE_UPDATE_API = "api/1/push_inbox_update"
    private let STATE_UPDATE_PARAM_READ = "R"
    private let STATE_UPDATE_PARAM_DELETE = "D"
    private let REST_MAX_ATTEMPTS = 3
    private let EVENT_CAMPAIGN_TYPE_PIM = "push_inbox"
    private let EVENT_ACTION_TYPE_PIM_READ = "read"
    private let EVENT_ACTION_TYPE_PIM_ENGAGED = "engaged"
    private let EVENT_ACTION_TYPE_PIM_DELETE = "delete"
    private let EVENT_PAYLOAD_PIM_STATE = "state"
    private let EVENT_PAYLOAD_PIM_MESSAGE_ID = "messageId"
    private let EVENT_PAYLOAD_TRACKING_DATA = "trackingData"

    private let serialQueue = DispatchQueue(label: "PushInbox")
    private var inbox: [SwrvePushInboxMessage] = []
    private var inboxFile: SwrveSignatureProtectedFile?
    private var user: String?
    private var fileManager = FileManager.default
    private var baseUrl: String?
    private var apiKey: String?
    private var signatureKey: String?
    private var restClient: SwrveRESTClient

    @objc public init(
        _ user: String,
        baseUrl: String,
        apiKey: String,
        signatureKey: String,
        restClient: SwrveRESTClient
    ) {
        self.user = user
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.signatureKey = signatureKey
        self.restClient = restClient
        super.init()

        initInboxFromCacheFile()
    }

    // swiftlint:disable empty_count
    // swiftlint:disable force_cast
    @objc public func updatePushInbox(_ inboxMessages: NSArray?, writeToCache: Bool) {

        guard let inboxMessages else {
            SwrveLogger.logError("Error parsing Push Inbox JSON")
            return
        }

        serialQueue.sync {
            if inboxMessages.count == 0 {
                self.inbox = []
            } else {

                self.inbox.removeAll()
                inboxMessages.forEach { dict in
                    do {
                        try self.inbox.append(SwrvePushInboxMessage(dict as! NSDictionary))
                    } catch {
                        SwrveLogger.logError("Failed to parse an inbox message - \(error)")
                    }
                }
            }

            if writeToCache {
                self.writeToInboxCache(inboxMessages)
            }
        }
    }

    @objc public func messages() -> [SwrvePushInboxMessage] {
        serialQueue.sync {
            //TODO - clone this?? - check objects can't be altered
            inbox
        }
    }

    @objc public func filteredMessages() -> [SwrvePushInboxMessage] {
        serialQueue.sync {

            var result: [SwrvePushInboxMessage] = []
            if inbox.isEmpty { return result }

            let now = Date()

            for message in inbox {
                let messageEndDate = Date.init(epochMilliseconds: message.endDate)
                if messageEndDate < now {
                    SwrveLogger.logDebug("Push Inbox Message \(message.messageId) end date has expired.")
                    continue
                }
                result.append(message)
            }

            return result
        }
    }

    private func initInboxFromCacheFile() {
        do {
            try fileManager.createDirectory(
                atPath: SwrveLocalStorage.swrveCacheFolder(),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            SwrveLogger.logError("Error creating \(SwrveLocalStorage.swrveCacheFolder().nilSafe): \(error)")
        }

        inboxFile = SwrveSignatureProtectedFile()
        inboxFile?.protectedFileType(
            Int32(SWRVE_PUSH_INBOX_FILE),
            userID: self.user,
            signatureKey: self.signatureKey,
            errorDelegate: nil)

        let content = inboxFile?.readWithRespectToPlatform()

        guard let content else {
            return
        }

        do {
            let jsonArray = try JSONSerialization.jsonObject(with: content) as? NSArray
            updatePushInbox(jsonArray, writeToCache: false)
        } catch {
            SwrveLogger.logError("Error updating Inbox from cached content - \(error)")
        }
    }

    private func writeToInboxCache(_ messages: NSArray) {
        do {
            let content = try JSONSerialization.data(withJSONObject: messages)
            inboxFile?.writeWithRespect(toPlatform: content)
        } catch {
            SwrveLogger.logError("Error caching Push Inbox JSON")
        }
    }

    private func stateUpdateBody(messageId: UInt64, state: String) -> String? {
        var urlParser = URLComponents()
        urlParser.queryItems = [
            URLQueryItem(name: "user", value: self.user),
            URLQueryItem(name: "api_key", value: self.apiKey),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "message_id", value: String(messageId))
        ]
        return urlParser.percentEncodedQuery
    }

    @objc public func getPushInboxMessage(_ messageId: UInt64) -> SwrvePushInboxMessage? {
        serialQueue.sync {
            inbox.first(where: { $0.messageId == messageId })
        }
    }

    @objc public func readMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate?) {

        let handler: RestHandlerClosure = { response, data, error in

            let statusCode = response?.http?.statusCode ?? 0
            let httpStatus = response?.http?.httpStatus

            var result: SwrvePushInboxResult

            if httpStatus == HttpStatus.HTTP_SUCCESS {
                self.updateSuccess(messageId: messageId, state: SwrvePushInboxMessageState.READ, responseBody: data)
                result = SwrvePushInboxResult(SwrvePushInboxResultCode.SUCCESS, "", statusCode)
            } else {
                let errorMessage = "Push Inbox Message \(messageId) failed to mark as read. Server response code:\(statusCode)"
                result = SwrvePushInboxResult(SwrvePushInboxResultCode.ERROR, errorMessage, statusCode)
            }

            listener?.onComplete(messageId, result: result)
        }
        let body = self.stateUpdateBody(messageId: messageId, state: STATE_UPDATE_PARAM_READ)

        executePushInboxRestRequest(body: body!, handler: handler)
    }

    @objc public func engageMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate?) {

        if let message = getPushInboxMessage(messageId) {
            sendEvent(EVENT_ACTION_TYPE_PIM_ENGAGED, message.variantId, message.messageId, message.state, message.trackingData)
        }

        readMessage(messageId, listener: listener)
    }

    @objc public func deleteMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate?) {

        let handler: RestHandlerClosure = { response, data, error in

            let statusCode = response?.http?.statusCode ?? 0
            let httpStatus = response?.http?.httpStatus

            var result: SwrvePushInboxResult

            if httpStatus == HttpStatus.HTTP_SUCCESS {
                self.updateSuccess(messageId: messageId, state: SwrvePushInboxMessageState.DELETED, responseBody: data)
                result = SwrvePushInboxResult(SwrvePushInboxResultCode.SUCCESS, "", statusCode)
            } else {
                let errorMessage = "Push Inbox Message \(messageId) failed to delete. Server response code:\(statusCode)"
                result = SwrvePushInboxResult(SwrvePushInboxResultCode.ERROR, errorMessage, statusCode)
            }
            listener?.onComplete(messageId, result: result)
        }
        let body = self.stateUpdateBody(messageId: messageId, state: STATE_UPDATE_PARAM_DELETE)
        executePushInboxRestRequest(body: body!, handler: handler)
    }

    typealias RestHandlerClosure = (URLResponse?, Data?, Error?) -> Void

    private func executePushInboxRestRequest(body: String, handler: @escaping RestHandlerClosure) {
        var attempt = 1
        let postData = NSMutableData(data: body.data(using: String.Encoding.utf8)!)
        let url = URL(string: STATE_UPDATE_API, relativeTo: URL(string: self.baseUrl!))!
        var request = URLRequest(
            url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: self.restClient.timeoutInterval)
        request.httpMethod = "POST"
        request.httpBody = postData as Data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("\(postData.count)", forHTTPHeaderField: "Content-Length")
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest

        var localHandler: RestHandlerClosure?
        localHandler = { [weak self] response, data, error in
            guard let self = self else { return }
            let status = (response as! HTTPURLResponse).httpStatus
            let statusCode = response?.http?.statusCode ?? 0
            if status != HttpStatus.HTTP_SUCCESS && attempt < self.REST_MAX_ATTEMPTS {
                SwrveLogger.logWarning("Retrying Push Inbox REST error \(statusCode) on attempt \(attempt)")
                attempt += 1
                self.restClient.sendHttpRequest(mutableRequest, completionHandler: localHandler)
            } else {
                handler(response, data, error)
            }
        }

        self.restClient.sendHttpRequest(mutableRequest, completionHandler: localHandler)
    }

    private func updateSuccess(messageId: UInt64, state: SwrvePushInboxMessageState, responseBody: Data?) {
        SwrveLogger.logDebug("Push Inbox Message \(messageId) marked as \(state).")
        guard let message = getPushInboxMessage(messageId) else {
            return
        }

        // Send event with current state (before updating local state) if the response body contains json {"state": "modified"}
        if let data = responseBody,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let jsonState = json["state"] as? String,
            jsonState == "modified"
        {
            if state == SwrvePushInboxMessageState.READ {
                self.sendEvent(self.EVENT_ACTION_TYPE_PIM_READ, message.variantId, messageId, message.state, message.trackingData)
            } else if state == SwrvePushInboxMessageState.DELETED {
                self.sendEvent(self.EVENT_ACTION_TYPE_PIM_DELETE, message.variantId, messageId, message.state, message.trackingData)
            }
        }

        // Update the local state of the message or delete
        if state == SwrvePushInboxMessageState.READ {
            message.state = SwrvePushInboxMessageState.READ
        } else if state == SwrvePushInboxMessageState.DELETED {
            self.serialQueue.sync {
                self.inbox.removeAll(where: { m -> Bool in
                    m == message
                })
            }
        }
    }

    private func sendEvent(
        _ actionType: String, _ variantId: UInt64, _ messageId: UInt64, _ state: SwrvePushInboxMessageState, _ trackingData: String
    ) {
        guard let sdkCommon = SwrveCommon.sharedInstance() else {
            SwrveLogger.logError("SwrveCommon instance not found - Send Event failed.")
            return
        }
        let payload = NSMutableDictionary()
        payload[EVENT_PAYLOAD_PIM_MESSAGE_ID] = String(messageId)
        if actionType != EVENT_ACTION_TYPE_PIM_READ {
            let stateString = state == SwrvePushInboxMessageState.READ ? "read" : "unread"
            payload[EVENT_PAYLOAD_PIM_STATE] = stateString
        }
        if !trackingData.isEmpty {
            payload[EVENT_PAYLOAD_TRACKING_DATA] = trackingData
        }

        let eventDict = NSMutableDictionary()
        eventDict["id"] = String(variantId)
        eventDict["campaignType"] = EVENT_CAMPAIGN_TYPE_PIM
        eventDict["actionType"] = actionType
        eventDict["payload"] = payload

        sdkCommon.queueEvent("generic_campaign_event", data: eventDict, triggerCallback: false)
        sdkCommon.sendQueuedEvents()
    }

}
