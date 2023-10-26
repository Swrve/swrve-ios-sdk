
import Foundation

public class SwrveLiveActivityStorage {
    
    private let userDefaults: UserDefaults
    private let storageKey: String

    public init(
        userDefaults: UserDefaults = UserDefaults.standard,
        storageKey: String = "SwrveTrackedActivites"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }
}
    
 extension SwrveLiveActivityStorage {
    
     public func remove(withId id: String) {
        var activities = fetchActivities()
        activities.removeAll(where: { $0.id == id })
        saveActivities(activities)
    }

     public func remove(withName activityName: String) {
        var activities = fetchActivities()
        activities.removeAll(where: { $0.activityName == activityName })
        saveActivities(activities)
    }

     public func save(_ activity: SwrveLiveActivityData) {
        var activities = fetchActivities()
        
        activities.removeAll(where: { $0.id == activity.id })
        activities.append(activity)
        
        saveActivities(activities)
    }
    
     func fetchActivities() -> [SwrveLiveActivityData] {
         guard let data = userDefaults.data(forKey: storageKey),
               let activities = try? JSONDecoder().decode([SwrveLiveActivityData].self, from: data) else {
             return []
         }
         return activities
     }
    
     func saveActivities(_ activities: [SwrveLiveActivityData]) {
        let encodedActivities = try? JSONEncoder().encode(activities)
        userDefaults.set(encodedActivities, forKey: storageKey)
    }

}
