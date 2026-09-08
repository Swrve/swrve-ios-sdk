import SnapshotTesting
import UIKit
import XCTest

@testable import SwrveSDK

class SwrveTestIAMPages: XCTestCase {

    override class func setUp() {
        SwrveTestHelper.setUp()
        SwrveTestHelper.createDummyAssets([
            "6c871366c876fdb495d96eff3d2905f9d4594c62",
            "8f984a803374d7c03c97dd122bce3ccf565bbdb5",
            "8721fd4e657980a5e12d498e73aed6e6a565dfca",
            "97c5df26c8e8fcff8dbda7e662d4272a6a94af7e",
            "background",
            "pressed_bg",
            "focused_bg",
            "default_icon",
            "default_bg"
        ])

        SwrveTestHelper.createDummyAssets(["16939daf143a8352e903c501ab1528969780ded1"], withResourceName: "breaking-bad", ofType: "jpg")
        SwrveTestHelper.createDummyAssets(["e69fb2f264bebaad0a11c2c83fd1d2b73bf03990"], withResourceName: "breaking-bad", ofType: "jpg")
        SwrveTestHelper.createDummyAssets(["374fc78621fa8b4e1944c33c0924702ba01a1eb9"], withResourceName: "breaking-bad", ofType: "jpg")

        UIView.setAnimationsEnabled(false)
    }

    override class func tearDown() {
        SwrveTestHelper.tearDown()
    }

    func testIAMCampainWithCenterImageAndBottomButton() throws {
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("Not Running this test on iPad")
            return
        }

        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        guard
            let swrve = SwrveSDK.sharedInstance as? Swrve,
            let controller = swrve.messaging
        else {
            return
        }

        let mockedJSON = try getMockDataAsDictionary(fileName: "campaigns_snapshot")
        controller.updateCampaigns(mockedJSON, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)

        if let campaign = controller.campaigns[1] as? SwrveInAppCampaign {
            let vc = SwrveMessageViewController(messageController: controller, message: campaign.message!, personalization: [:])
            runSnapshot(for: vc)
        }

    }

    func testIAMCampainWithCenterImageAndBottomButton2() throws {
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("Not Running this test on iPad")
            return
        }

        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        guard
            let swrve = SwrveSDK.sharedInstance as? Swrve,
            let controller = swrve.messaging
        else {
            return
        }

        let mockedJSON = try getMockDataAsDictionary(fileName: "campaigns_snapshot")
        controller.updateCampaigns(mockedJSON, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)

        if let campaign = controller.campaigns[2] as? SwrveInAppCampaign {
            let vc = SwrveMessageViewController(messageController: controller, message: campaign.message!, personalization: [:])
            runSnapshot(for: vc)
        }

    }

    func testIAMCampainWithCenterImageAndBottomButton3() throws {
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("Not Running this test on iPad")
            return
        }

        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        guard
            let swrve = SwrveSDK.sharedInstance as? Swrve,
            let controller = swrve.messaging
        else {
            return
        }

        let mockedJSON = try getMockDataAsDictionary(fileName: "campaigns_snapshot")
        controller.updateCampaigns(mockedJSON, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)

        if let campaign = controller.campaigns[3] as? SwrveInAppCampaign {
            let vc = SwrveMessageViewController(messageController: controller, message: campaign.message!, personalization: [:])
            runSnapshot(for: vc)
        }

    }

    func testIAMCampainWithCenterImageAndBottomButton4() throws {
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("Not Running this test on iPad")
            return
        }

        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        guard
            let swrve = SwrveSDK.sharedInstance as? Swrve,
            let controller = swrve.messaging
        else {
            return
        }

        let mockedJSON = try getMockDataAsDictionary(fileName: "campaigns_snapshot")
        controller.updateCampaigns(mockedJSON, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)

        if let campaign = controller.campaigns[4] as? SwrveInAppCampaign {
            let vc = SwrveMessageViewController(messageController: controller, message: campaign.message!, personalization: [:])
            runSnapshot(for: vc)
        }

    }

}
