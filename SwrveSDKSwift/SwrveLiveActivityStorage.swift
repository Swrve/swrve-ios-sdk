import Foundation

public class SwrveLiveActivityStorage {

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let pushToStartTokenStorageKey: String
    private let activitiesEnabledKey: String
    private let frequentPushEnabledKey: String

    public init(
        userDefaults: UserDefaults = UserDefaults.standard,
        storageKey: String = "SwrveTrackedActivites",
        pushToStartTokenStorageKey: String = "SwrvePushToStartToken",
        activitiesEnabledKey: String = "SwrveActivitiesEnabled",
        frequentPushEnabledKey: String = "SwrveFrequentPushEnabled"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.pushToStartTokenStorageKey = pushToStartTokenStorageKey
        self.activitiesEnabledKey = activitiesEnabledKey
        self.frequentPushEnabledKey = frequentPushEnabledKey
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
            let activities = try? JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        else {
            return []
        }
        return activities
    }

    func fetchActivity(withUniqueActivityId uniqueActivityId: String) -> SwrveLiveActivityData? {
        fetchActivities().first(where: { $0.id == uniqueActivityId })
    }

    func saveActivities(_ activities: [SwrveLiveActivityData]) {
        let encodedActivities = try? JSONEncoder().encode(activities)
        userDefaults.set(encodedActivities, forKey: storageKey)
    }

}

extension SwrveLiveActivityStorage {

    func savePushToStartToken(_ token: String) {
        userDefaults.set(token, forKey: pushToStartTokenStorageKey)
    }

    func fetchPushToStartToken() -> String? {
        userDefaults.string(forKey: pushToStartTokenStorageKey)
    }

    func saveActivitiesEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: activitiesEnabledKey)
    }

    func saveFrequentPushEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: frequentPushEnabledKey)
    }
}
