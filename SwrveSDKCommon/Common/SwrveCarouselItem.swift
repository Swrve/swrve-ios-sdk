import Foundation

public enum SwrveCarouselItemActionType {
    case openUrl
    case openApp
}

public class SwrveCarouselItem {

    public private(set) var imageUrl: String
    public private(set) var title: String?
    public private(set) var body: String?
    public private(set) var action: String?
    public private(set) var actionType: SwrveCarouselItemActionType = .openApp

    public init?(dictionary: [AnyHashable: Any]) {
        guard let imageUrl = SwrveCarouselItem.string(from: dictionary[SwrveNotificationCarouselImageUrlKey]),
            !imageUrl.isEmpty
        else {
            return nil
        }
        self.imageUrl = imageUrl
        self.title = SwrveCarouselItem.string(from: dictionary[SwrveNotificationTitleKey])
        self.body = SwrveCarouselItem.string(from: dictionary[SwrveNotificationBodyKey])
        self.action = SwrveCarouselItem.string(from: dictionary[SwrveNotificationButtonActionKey])
        self.actionType = SwrveCarouselItem.actionType(from: dictionary[SwrveNotificationButtonActionTypeKey])
    }

    public static func items(fromSwrvePayload swrvePayload: [AnyHashable: Any]?) -> [SwrveCarouselItem]? {
        guard let rawCarousel = swrvePayload?[SwrveNotificationCarouselKey],
            let elements = rawCarousel as? [Any],
            !elements.isEmpty
        else {
            return nil
        }

        var items = [SwrveCarouselItem]()
        for element in elements {
            guard let dictionary = element as? [AnyHashable: Any],
                let item = SwrveCarouselItem(dictionary: dictionary)
            else {
                return nil
            }
            items.append(item)
        }
        return items
    }

    private static func string(from value: Any?) -> String? {
        guard let value = value, !(value is NSNull) else { return nil }
        return value as? String
    }

    private static func actionType(from value: Any?) -> SwrveCarouselItemActionType {
        guard let rawValue = string(from: value) else { return .openApp }
        return rawValue == SwrveNotificationCustomButtonUrlIdentiferKey ? .openUrl : .openApp
    }
}
