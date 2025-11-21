import XCTest

@testable import SwrveSDK

class SwrveCampaignTests: XCTestCase {

    let defaultTimezone = NSTimeZone.default

    override func tearDown() {
        super.tearDown()
        NSTimeZone.default = defaultTimezone
    }

    func testDateStartAndEndWithEmptyDateIso() {
        let campaign = createCampaign(currentTime: Date(), startDateIso: "", endDateIso: "", timezoneType: "global")
        XCTAssertEqual(campaign.dateStart, Date.distantFuture, "dateStart should be distantFuture when startDateIso is empty")
        XCTAssertEqual(campaign.dateEnd, Date.distantPast, "dateEnd should be distantPast when endDateIso is empty")
    }

    func testDateStartAndEndWithInvalidDateIso() {
        let campaign = createCampaign(currentTime: Date(), startDateIso: "invalid-date", endDateIso: "invalid-date", timezoneType: "global")
        XCTAssertEqual(campaign.dateStart, Date.distantFuture, "dateStart should be distantFuture when startDateIso is empty")
        XCTAssertEqual(campaign.dateEnd, Date.distantPast, "dateEnd should be distantPast when endDateIso is empty")
    }

    func testDateStartWithValidIsoDateGlobalTimezone() {
        let startIsoDate = "2023-09-23T10:00:00Z"
        let endIsoDate = "2053-09-23T10:00:00Z"
        let campaign = createCampaign(currentTime: Date(), startDateIso: startIsoDate, endDateIso: endIsoDate, timezoneType: "global")
        let expectedStartDate = ISO8601DateFormatter().date(from: startIsoDate)
        XCTAssertEqual(campaign.dateStart, expectedStartDate, "dateStart should match the expected ISO 8601 date in GLOBAL timezone")
        let expectedEndDate = ISO8601DateFormatter().date(from: endIsoDate)
        XCTAssertEqual(campaign.dateEnd, expectedEndDate, "dateEnd should match the expected ISO 8601 date in GLOBAL timezone")
    }

    func testIsActiveBeforeCampaignStart() throws {
        // Create a campaign with a start date in the future
        let currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-21T12:00:00Z", timezoneType: .GLOBAL))
        let futureStartDate = ISO8601DateFormatter().string(from: currentDate.addingTimeInterval(60 * 60 * 24))  // 1 day in future
        let futureEndDate = ISO8601DateFormatter().string(from: Date.distantFuture.addingTimeInterval(60 * 60 * 24))  // Never ends
        let campaign = createCampaign(currentTime: currentDate, startDateIso: futureStartDate, endDateIso: futureEndDate, timezoneType: "global")

        // Expect the campaign to be inactive because it hasn't started yet
        let reasons = NSMutableDictionary()
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive if it hasn't started yet")
        let expectedReason = "Campaign 123 has not started yet. Start:2024-09-22 12:00:00 GMT TimezoneType:global Now:2024-09-21 12:00:00 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for inactivity before campaign start")
    }

    func testIsActiveAfterCampaignEnd() throws {
        // Create a campaign with an end date in the past
        let currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-21T12:00:00Z", timezoneType: .GLOBAL))
        let pastStartDate = ISO8601DateFormatter().string(from: Date.distantPast.addingTimeInterval(60 * 60 * 24))  // always started
        let pastEndDate = ISO8601DateFormatter().string(from: currentDate.addingTimeInterval(-60 * 60 * 24))  // 1 day in past
        let campaign = createCampaign(currentTime: currentDate, startDateIso: pastStartDate, endDateIso: pastEndDate, timezoneType: "global")

        // Expect the campaign to be inactive because it has ended
        let reasons = NSMutableDictionary()
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive if it has already ended")
        let expectedReason = "Campaign 123 has finished. End:2024-09-20 12:00:00 GMT TimezoneType:global Now:2024-09-21 12:00:00 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for inactivity after campaign end")
    }

    func testIsActiveDuringCampaign() {
        // Create a campaign that is currently active
        let pastStartDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60 * 60 * 24))  // 1 day in past
        let futureEndDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(60 * 60 * 24))  // 1 day in future
        let campaign = createCampaign(currentTime: Date(), startDateIso: pastStartDate, endDateIso: futureEndDate, timezoneType: "global")

        // Expect the campaign to be active
        let reasons = NSMutableDictionary()
        XCTAssertTrue(campaign.isActive(at: Date(), withReasons: reasons), "Campaign should be active within start and end date")
        XCTAssertTrue(reasons.allValues.isEmpty, "No reason for inactivity expected")
    }

    func testParsingValidBlackoutDates() {
        let json: [String: Any] = [
            "blackout_dates": [
                ["from": "2024-09-25T23:00:00", "to": "2024-09-26T22:59:59"],
                ["from": "2024-10-01T00:00:00", "to": "2024-10-02T23:59:59"]
            ]
        ]

        let campaign = SwrveCampaign(at: Date(), from: json, campaignType: SWRVE_CAMPAIGN_IAM)

        XCTAssertEqual(campaign.blackoutDates.count, 2)
        XCTAssertNotNil(campaign.blackoutDates[0].from)
        XCTAssertEqual(campaign.blackoutDates[0].from, "2024-09-25T23:00:00")
        XCTAssertNotNil(campaign.blackoutDates[0].to)
        XCTAssertEqual(campaign.blackoutDates[0].to, "2024-09-26T22:59:59")
        XCTAssertNotNil(campaign.blackoutDates[1].from)
        XCTAssertEqual(campaign.blackoutDates[1].from, "2024-10-01T00:00:00")
        XCTAssertNotNil(campaign.blackoutDates[1].to)
        XCTAssertEqual(campaign.blackoutDates[1].to, "2024-10-02T23:59:59")
    }

    func testParsingValidIntervalTimes() {
        let json: [String: Any] = [
            "interval_times": [
                ["from": "09:00:00", "to": "13:00:00"],
                ["from": "14:00:00", "to": "17:30:00"]
            ]
        ]

        let campaign = SwrveCampaign(at: Date(), from: json, campaignType: SWRVE_CAMPAIGN_IAM)

        XCTAssertEqual(campaign.intervalTimes.count, 2)
        XCTAssertNotNil(campaign.intervalTimes[0].from)
        XCTAssertEqual(campaign.intervalTimes[0].from, "09:00:00")
        XCTAssertNotNil(campaign.intervalTimes[0].to)
        XCTAssertEqual(campaign.intervalTimes[0].to, "13:00:00")
        XCTAssertNotNil(campaign.intervalTimes[1].from)
        XCTAssertEqual(campaign.intervalTimes[1].from, "14:00:00")
        XCTAssertNotNil(campaign.intervalTimes[1].to)
        XCTAssertEqual(campaign.intervalTimes[1].to, "17:30:00")
    }

    func testIsActive_WithBlackouts() throws {

        // Ensure start and end date of test campaigns are always active
        let startDateIso = "1970-01-01T00:00:00Z"
        let endDateIso = "4000-01-01T00:00:00Z"

        // 3 blackouts on the 22nd, 24th and 26th
        let blackoutDate1 = try createBlackoutDate("2024-09-22T00:00:00Z")
        let blackoutDate2 = try createBlackoutDate("2024-09-24T00:00:00Z")
        let blackoutDate3 = try createBlackoutDate("2024-09-26T00:00:00Z")

        // 21st - so campaign should not be in blackout period
        var currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-21T12:00:00Z", timezoneType: .GLOBAL))
        var campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        let reasons = NSMutableDictionary()
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // 22nd - so campaign should be in blackout period
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-22T12:00:00Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive if it hasn't started yet")
        var expectedReason =
            "Campaign 123 is in blackout period. Blackout from:2024-09-22 00:00:00 GMT to:2024-09-23 00:00:00 GMT "
            + "TimezoneType:global Now:2024-09-22 12:00:00 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for blackout")

        // 23rd - so campaign should not be in blackout period
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-23T12:00:00Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // 24th - so campaign should be in blackout period
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-24T12:00:00Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive if it hasn't started yet")
        expectedReason =
            "Campaign 123 is in blackout period. Blackout from:2024-09-24 00:00:00 GMT to:2024-09-25 00:00:00 GMT "
            + "TimezoneType:global Now:2024-09-24 12:00:00 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for blackout")

        // 25th - so campaign should not be in blackout period
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-25T12:00:00Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // 26th - so campaign should be in blackout period
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-26T12:00:00Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            blackoutDates: [blackoutDate1, blackoutDate2, blackoutDate3])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive if it hasn't started yet")
        expectedReason =
            "Campaign 123 is in blackout period. Blackout from:2024-09-26 00:00:00 GMT to:2024-09-27 00:00:00 GMT "
            + "TimezoneType:global Now:2024-09-26 12:00:00 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for blackout")
    }

    func testIsActive_WithIntervalTimes_Global() throws {

        // Ensure start and end date of test campaigns are always active
        let startDateIso = "1970-01-01T00:00:00Z"
        let endDateIso = "4000-01-01T00:00:00Z"

        // 2 interval times 09:00:00-13:00:00 and 14:00:00-17:30:00
        let intervalTime1 = SwrveCampaign.SwrveIntervalTime(from: "09:00:00", to: "13:00:00")
        let intervalTime2 = SwrveCampaign.SwrveIntervalTime(from: "14:00:00", to: "17:30:00")

        // Set time now to 10th September 2024 8:59:59 UTC
        var currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T08:59:59Z", timezoneType: .GLOBAL))
        var campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        let reasons = NSMutableDictionary()
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        var expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 08:59:59 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 09:00:01 so its just inside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T09:00:01Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 12:59:59 so its just inside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T12:59:59Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 13:00:01 so its just outside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T13:00:01Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 13:00:01 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 13:59:59 so its just outside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T13:59:59Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 13:59:59 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 14:00:01 so its just inside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T14:00:01Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 17:29:59 so its just inside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T17:29:59Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 17:30:01 so its just outside the interval
        currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T17:30:01Z", timezoneType: .GLOBAL))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 17:30:01 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")
    }

    func testIsActive_WithIntervalTimes_Global_different_timezone() throws {

        // Ensure start and end date of test campaigns are always active
        let startDateIso = "1970-01-01T00:00:00Z"
        let endDateIso = "4000-01-01T00:00:00Z"

        // 2 interval times 09:00:00-13:00:00 and 14:00:00-17:30:00
        let intervalTime1 = SwrveCampaign.SwrveIntervalTime(from: "09:00:00", to: "13:00:00")
        let intervalTime2 = SwrveCampaign.SwrveIntervalTime(from: "14:00:00", to: "17:30:00")

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")  // Set timezone to New York (Eastern Time)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Current date is 10th September 2024 04:59:59 New York (08:59:59 UTC) so it should be outside the interval
        var currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T04:59:59"))
        var campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        let reasons = NSMutableDictionary()
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        var expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 08:59:59 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 05:00:01 New York (09:00:01 UTC) so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T05:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 08:59:59 New York (12:59:59 UTC) so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T08:59:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 09:00:01 New York (13:00:01 UTC) so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T09:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 13:00:01 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 09:59:59 New York (13:59:59 UTC) so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T09:59:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 13:59:59 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 10:00:01 New York (14:00:01 UTC) so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T10:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 13:29:59 New York (17:29:59 UTC) so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T13:29:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 13:30:01 New York (17:30:01 UTC) so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T13:30:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "global",
            intervalTimes: [intervalTime1, intervalTime2])
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:global Now:2024-09-10 17:30:01 GMT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")
    }

    func testIsActive_WithIntervalTimes_Local() throws {

        // Ensure start and end date of test campaigns are always active
        let startDateIso = "1970-01-01T00:00:00"
        let endDateIso = "4000-01-01T00:00:00"

        // 2 interval times 09:00:00-13:00:00 and 14:00:00-17:30:00
        let intervalTime1 = SwrveCampaign.SwrveIntervalTime(from: "09:00:00", to: "13:00:00")
        let intervalTime2 = SwrveCampaign.SwrveIntervalTime(from: "14:00:00", to: "17:30:00")

        let timezoneNY = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        NSTimeZone.default = timezoneNY
        let formatter = DateFormatter()
        formatter.timeZone = timezoneNY  // Set timezone to New York (Eastern Time)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Current date is 10th September 2024 8:59:59 EST so it should be outside the interval
        var currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T08:59:59"))
        var campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        let reasons = NSMutableDictionary()
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        var expectedReason = "Campaign 123 is outside active interval time. TimezoneType:local Now:2024-09-10 08:59:59 EDT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 09:00:01 so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T09:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 12:59:59 so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T12:59:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 13:00:01 so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T13:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:local Now:2024-09-10 13:00:01 EDT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 13:59:59 so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T13:59:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:local Now:2024-09-10 13:59:59 EDT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")

        // Set time now to 10th at 14:00:01 so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T14:00:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 17:29:59 so its just inside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T17:29:59"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertTrue(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be active")

        // Set time now to 10th at 17:30:01 so its just outside the interval
        currentDate = try XCTUnwrap(formatter.date(from: "2024-09-10T17:30:01"))
        campaign = createCampaign(
            currentTime: currentDate, startDateIso: startDateIso, endDateIso: endDateIso, timezoneType: "local",
            intervalTimes: [intervalTime1, intervalTime2], timezone: timezoneNY)
        XCTAssertFalse(campaign.isActive(at: currentDate, withReasons: reasons), "Campaign should be inactive")
        expectedReason = "Campaign 123 is outside active interval time. TimezoneType:local Now:2024-09-10 17:30:01 EDT"
        XCTAssertTrue(reasons.allValues.compactMap { $0 as? String }.contains(expectedReason), "Expected reason for timeout interval")
    }

    func testHasActiveTimeInterval() throws {

        // time 10:00:00am so its inside the interval
        let currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-10T10:00:00Z", timezoneType: .GLOBAL))

        // No intervals
        var campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [])
        XCTAssertTrue(campaign.hasActiveTimeInterval(now: currentDate))

        // valid time in the interval
        var interval = SwrveCampaign.SwrveIntervalTime(from: "09:00:00", to: "13:00:00")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertTrue(campaign.hasActiveTimeInterval(now: currentDate))

        // valid time outside the interval
        interval = SwrveCampaign.SwrveIntervalTime(from: "14:00:00", to: "17:00:00")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertFalse(campaign.hasActiveTimeInterval(now: currentDate))

        // times must not go across midnight
        interval = SwrveCampaign.SwrveIntervalTime(from: "13:00:00", to: "09:00:00")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertFalse(campaign.hasActiveTimeInterval(now: currentDate))

        // invalid time
        interval = SwrveCampaign.SwrveIntervalTime(from: "", to: "")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertFalse(campaign.hasActiveTimeInterval(now: currentDate))

        // invalid time
        interval = SwrveCampaign.SwrveIntervalTime(from: "09:00:00", to: "1:mm:ss")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertFalse(campaign.hasActiveTimeInterval(now: currentDate))

        // invalid time
        interval = SwrveCampaign.SwrveIntervalTime(from: "09:XX:XX", to: "13:00:00")
        campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global", intervalTimes: [interval])
        XCTAssertFalse(campaign.hasActiveTimeInterval(now: currentDate))
    }

    func testSecondsSinceMidnight() {

        let currentDate = Date()
        let campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global")
        do {
            let seconds = try campaign.secondsSinceMidnight(from: "1:15:45")
            let expectedSeconds = 1 * 3600 + 15 * 60 + 45  // 01:15:45 in seconds
            XCTAssertEqual(seconds, expectedSeconds, "The number of seconds since midnight should match the input time.")
        } catch {
            XCTFail("secondsSinceMidnight threw an error: \(error)")
        }
    }

    func testSecondsSinceMidnightGlobal() throws {

        let currentDate = try XCTUnwrap(SwrveUtilsSwift.parseIso8601Date("2024-09-21T01:15:45Z", timezoneType: .GLOBAL))
        let campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global")
        do {
            let seconds = try campaign.secondsSinceMidnight(from: currentDate, timezoneType: .GLOBAL)
            let expectedSeconds = 1 * 3600 + 15 * 60 + 45  // 01:15:45 in seconds
            XCTAssertEqual(seconds, expectedSeconds, "The number of seconds since midnight in GLOBAL should match the input time.")
        } catch {
            XCTFail("secondsSinceMidnight (GLOBAL) threw an error: \(error)")
        }
    }

    func testSecondsSinceMidnightLocal() throws {

        NSTimeZone.default = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")  // Set timezone to New York (Eastern Time)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let currentDate = try XCTUnwrap(formatter.date(from: "2024-09-21T01:15:45"))
        let campaign = createCampaign(currentTime: currentDate, startDateIso: "", endDateIso: "", timezoneType: "global")
        do {
            let seconds = try campaign.secondsSinceMidnight(from: currentDate, timezoneType: .LOCAL)
            let expectedSeconds = 1 * 3600 + 15 * 60 + 45  // 01:15:45 in seconds
            XCTAssertEqual(seconds, expectedSeconds, "The number of seconds since midnight in LOCAL should match the input time.")
        } catch {
            XCTFail("secondsSinceMidnight (LOCAL) threw an error: \(error)")
        }
    }

    // Helper function to create a SwrveCampaign with custom attribues
    func createCampaign(
        currentTime: Date, startDateIso: String, endDateIso: String, timezoneType: String,
        blackoutDates: [SwrveCampaign.SwrveBlackoutDate] = [],
        intervalTimes: [SwrveCampaign.SwrveIntervalTime] = [],
        timezone: TimeZone = .current
    ) -> SwrveCampaign {
        let json: [String: Any] = [
            "id": NSNumber(value: 123),
            "start_date_iso": startDateIso,
            "end_date_iso": endDateIso,
            "timezone_type": timezoneType,
            "blackout_dates": blackoutDates.map { ["from": $0.from, "to": $0.to] },
            "interval_times": intervalTimes.map { ["from": $0.from, "to": $0.to] }
        ]
        return SwrveCampaign(at: currentTime, from: json, campaignType: SWRVE_CAMPAIGN_IAM, timeZone: timezone)
    }

    // Helper function to create SwrveBlackoutDate objects
    func createBlackoutDate(_ isoDate: String) throws -> SwrveCampaign.SwrveBlackoutDate {
        guard let date = SwrveUtilsSwift.parseIso8601Date(isoDate, timezoneType: .GLOBAL) else {
            return SwrveCampaign.SwrveBlackoutDate(from: "", to: "")
        }
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let startOfDay = utcCalendar.startOfDay(for: date)
        let endOfDay = try XCTUnwrap(utcCalendar.date(byAdding: .day, value: 1, to: startOfDay))
        return SwrveCampaign.SwrveBlackoutDate(from: startOfDay.iso8601String, to: endOfDay.iso8601String)
    }
}

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)  // Set time zone to UTC
        return formatter.string(from: self)
    }
}
