
import Foundation

public struct SwrveLiveActivityData: Codable {
    
    public let id: String
    public let activityId: String
    public let activityName: String
    
    public init(id: String, activityId: String, activityName: String) {
        self.id = id
        self.activityId = activityId
        self.activityName = activityName
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case activityId = "activity_Id"
        case activityName = "activity_type_name"
    }
}

extension SwrveLiveActivityData: Equatable {
    public static func == (lhs: SwrveLiveActivityData, rhs: SwrveLiveActivityData) -> Bool {
         return lhs.id == rhs.id
     }
}

extension SwrveLiveActivityData: Hashable {
    public func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }
}
