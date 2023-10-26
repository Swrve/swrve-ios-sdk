
import XCTest
import SwrveSDK

extension SwrveLiveActivityData {
    static var mock: SwrveLiveActivityData {
        SwrveLiveActivityData(id: "123", activityId: "activity_id", activityName: "my activity")
    }
    static var anotherMockedData: SwrveLiveActivityData {
        SwrveLiveActivityData(id: "12345", activityId: "activity_id2", activityName: "my activity2")
    }
}

final class SwrveLiveStorageTests: XCTestCase {
    let userDefaults = UserDefaults.standard
    let storageKey = "key"

    override func setUp() {
        userDefaults.set([SwrveLiveActivityData](), forKey: storageKey)
    }

    func testThatActivityStorageSavesData() throws {
        let mockedAcivityData: SwrveLiveActivityData = .mock

        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: storageKey)
        sut.save(mockedAcivityData)
        
        let data = userDefaults.data(forKey: storageKey) ?? Data()
        let fetchedActivityData = try JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        
        XCTAssertEqual([mockedAcivityData], fetchedActivityData)
    }
    
    func testThatActivityStoragRemovesActivityWithGivenId() throws {
        let mockedAcivityData: SwrveLiveActivityData = .mock

        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: storageKey)
        sut.save(mockedAcivityData)
        
        sut.remove(withId: mockedAcivityData.id)
        
        let data = userDefaults.data(forKey: storageKey) ?? Data()
        let fetchedActivityData = try JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        
        XCTAssertTrue(fetchedActivityData.isEmpty)
    }
    
    func testThatActivityStoragRemovesActivityFromGivenListWithGivenId() throws {
        let mockedAcivityData: SwrveLiveActivityData = .mock

        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: storageKey)
        sut.save(mockedAcivityData)
        sut.save(SwrveLiveActivityData.anotherMockedData)
        
        sut.remove(withId: mockedAcivityData.id)
        
        let data = userDefaults.data(forKey: storageKey) ?? Data()
        let fetchedActivityData = try JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        
        XCTAssertEqual([SwrveLiveActivityData.anotherMockedData], fetchedActivityData)
    }
    
    func testThatActivityStoragRemovesActvityWithGivenName() throws {
        let mockedAcivityData: SwrveLiveActivityData = .mock

        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: storageKey)
        sut.save(mockedAcivityData)
        
        sut.remove(withName: mockedAcivityData.activityName)
        
        let data = userDefaults.data(forKey: storageKey) ?? Data()
        let fetchedActivityData = try JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        
        XCTAssertTrue(fetchedActivityData.isEmpty)
    }
    
    
    func testThatActivityStorageReturnsUniqueSavedList() throws {
        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: storageKey)
        // Intentionally adding same data twice to make sure it gets added only once
        sut.save(SwrveLiveActivityData.mock)
        sut.save(SwrveLiveActivityData.mock)
        sut.save(SwrveLiveActivityData.anotherMockedData)
        sut.save(SwrveLiveActivityData.anotherMockedData)
        
        let data = userDefaults.data(forKey: storageKey) ?? Data()
        let fetchedActivityData = try JSONDecoder().decode([SwrveLiveActivityData].self, from: data)
        
        XCTAssertEqual([SwrveLiveActivityData.mock, SwrveLiveActivityData.anotherMockedData], fetchedActivityData)
    }

}

