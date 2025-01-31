import XCTest
import Hippolyte
@testable import Insights

final class InsightsTests: XCTestCase {

    private let environment = "env_test"
    private let programToken = "pgt_test"
    private let sdkVersion = "sdk_test"
    private let apiUrl = InsightsTestHelper.restURL
    private let userToken = "usr_test"

    override func setUp() {
        super.setUp()
        EventManager.shared.deleteEvents(before: Date().epochMilliseconds())
        Insights.setup(environment: environment,
                       programToken: programToken,
                       sdkVersion: sdkVersion,
                       apiUrl: InsightsTestHelper.restURL,
                       userToken: userToken)
        XCTAssertNotNil(Insights.shared, "Shared instance shouldn't equal Nil")
        setupMockServerSuccess()
    }

    override func tearDown() {
        EventManager.shared.deleteEvents(before: Date().epochMilliseconds())
        if Hippolyte.shared.isStarted {
            Hippolyte.shared.stop()
        }
        super.tearDown()
    }

    private func setupMockServerSuccess() {
        let baseUrl = InsightsTestHelper.restURL
        let response = InsightsTestHelper.okHTTPResponse(for: "SuccessResponse")
        let request = InsightsTestHelper.buildPostRequest(baseUrl: baseUrl, response)
        InsightsTestHelper.setUpMockServer(request: request)
    }

    func skipTestTrackClick () {
        let pageName = "test_pageName"
        let pageGroup = "test_pageGroup"
        let link = "test_link"
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "Persistance storage should be empty")

        Insights.shared?.trackClick(pageName: pageName,
                                    pageGroup: pageGroup,
                                    link: link,
                                    params: [:])
        sleep(16)

        let events = EventManager.shared.loadEvents(before: Date().epochMilliseconds())
        XCTAssertEqual(events.count, 1, "There should be 1 record in database")
        assertPayload(events: events, pageName: pageName, pageGroup: pageGroup, link: link)
    }

    func testTrackImpression () {
        let pageName = "test_pageName"
        let pageGroup = "test_pageGroup"
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "Persistance storage should be empty")

        for _ in 1...2 {
            Insights.shared?.trackImpression(pageName: pageName,
                                             pageGroup: pageGroup,
                                             params: [:])
        }

        sleep(16)

        let events = EventManager.shared.loadEvents(before: Date().epochMilliseconds())
        XCTAssertEqual(events.count, 2, "There should be 2 Impression events in the storage")
        assertPayload(events: events, pageName: pageName, pageGroup: pageGroup)
    }

    func testTrackError () {
        let pageName = "test_pageName"
        let pageGroup = "test_pageGroup"
        let errorInfo = ErrorInfo(type: "test_type",
                                  message: "test_message",
                                  fieldName: "test_fieldName",
                                  description: "test_description",
                                  code: "test_code")
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "Persistance storage should be empty")
        for _ in 1...3 {
            Insights.shared?.trackError(pageName: pageName,
                                        pageGroup: pageGroup,
                                        errorInfo: errorInfo)
        }

        sleep(16)

        let events = EventManager.shared.loadEvents(before: Date().epochMilliseconds())
        XCTAssertEqual(events.count, 3, "There should be 3 Error events in the storage")
        assertPayload(events: events, pageName: pageName, pageGroup: pageGroup, errorInfo: errorInfo)
    }

    func skipTestTrackClick_withFlushRequired_maximumBatchSizeReached () {
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "Persistance storage should be empty")

        for _ in 1...15 {
            Insights.shared?.trackClick(pageName: "test_pageName",
                                        pageGroup: "test_pageGroup",
                                        link: "test_link",
                                        params: [:])
        }
//        sleep(17)

        let countAfterSave = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterSave, 5, "There should be 5 Click events in the storage")
    }

    func skipTestTrackClick_withFlushRequired_maximumBatchSizeReached_error () {
        let payload = InsightsTestHelper.getDataFromJson("EventPayload")
        InsightsTestHelper.setUpMockServer(request:
            setEventRequest(payload, (NSError(domain: "", code: -1009, userInfo: nil))))
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "Persistance storage should be empty")

        for eventNumber in 1...15 {
            Insights.shared?.trackClick(pageName: "test_pageName",
                                        pageGroup: "test_pageGroup",
                                        link: "test_link",
                                        params: [:])
            if eventNumber == 10 {
                // wait 1 second to separate other events (createdOn)
                sleep(16)
            }
        }

        sleep(16)

        let countAfterSave = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterSave, 15, "There should be 15 Click events in the storage")
    }

    func testClearInstance() {
        Insights.setup(environment: environment,
                       programToken: programToken,
                       sdkVersion: sdkVersion,
                       apiUrl: InsightsTestHelper.restURL,
                       userToken: userToken)
        XCTAssertNotNil(Insights.shared, "Insight instance should not equal to nil")
        Insights.clearInstance()
        XCTAssertNil(Insights.shared, "Insight instance should equal to nil")
    }
    
    private func setEventRequest(_ payload: Data, _ error: NSError? = nil) -> StubRequest {
        let response = InsightsTestHelper.setUpMockedResponse(payload: payload, error: error)
        let baseUrl = InsightsTestHelper.restURL
        return InsightsTestHelper.buildPostRequest(baseUrl: baseUrl, response)
    }

    private func assertPayload(events: [EventInsight],
                               pageName: String,
                               pageGroup: String,
                               link: String? = nil,
                               errorInfo: ErrorInfo? = nil) {
        XCTAssertNotNil(events[0].actor.trackingVisitId, "TrackingVisitId should not be nil")
        XCTAssertEqual(events[0].actor.trackingVisitorId, userToken, "TrackingVisitorId should be as expected")
        XCTAssertEqual(events[0].channel, "mobile", "Channel should not be nil")
        XCTAssertEqual(events[0].eventParams.count, 1, "EventParams count should be 1")
        XCTAssertEqual(events[0].eventParams[0].component, "hwiosuisdk", "Component should be as expected")
        XCTAssertNotNil(events[0].eventParams[0].deviceModel, "Device Model should not be nil")
        XCTAssertNotNil(events[0].eventParams[0].deviceName, "Device Name should not be nil")
        XCTAssertNotNil(events[0].eventParams[0].deviceType, "Device Type should not be nil")
        XCTAssertEqual(events[0].eventParams[0].sdkVersion, sdkVersion, "SDK Version should be as expected")
        XCTAssertNotNil(events[0].eventParams[0].screenWidth, "Screen Width should not be nil")
        XCTAssertNotNil(events[0].eventParams[0].screenHeight, "Screen Height should not be nil")
        XCTAssertEqual(events[0].eventParams[0].pageTechnologyFlag, "Swift", "Page Technology Flag should be as expected")
        XCTAssertEqual(events[0].eventParams[0].hyperwalletEnvironment, environment, "Environment should be as expected")
        XCTAssertNotNil(events[0].eventParams[0].orientation, "Orientation should not be nil")
        XCTAssertNotNil(events[0].eventParams[0].rosettaLanguage, "Language should not be nil")
        XCTAssertEqual(events[0].eventParams[0].hyperwalletIs, programToken, "IS should be as expected")
        XCTAssertEqual(events[0].eventParams[0].product, "dropin", "Product should be as expected")
        XCTAssertEqual(events[0].eventParams[0].pageName, pageName, "PageName should be as expected")
        XCTAssertEqual(events[0].eventParams[0].pageGroup, pageGroup, "Page Group should be as expected")
        if let link = link {
            XCTAssertEqual(events[0].eventParams[0].link, link, "Link should be as expected")
            XCTAssertEqual(events[0].eventParams[0].eventType, "cl", "Event Type should be as expected")
        } else if let errorInfo = errorInfo {
            XCTAssertEqual(events[0].eventParams[0].eventType, "err", "Event Type should be as expected")
            XCTAssertEqual(events[0].eventParams[0].errorCode, errorInfo.code, "Error code should be as expected")
            XCTAssertEqual(events[0].eventParams[0].errorDescription, errorInfo.description, "Error description should be as expected")
            XCTAssertEqual(events[0].eventParams[0].errorFieldName, errorInfo.fieldName, "Error fieldName should be as expected")
            XCTAssertEqual(events[0].eventParams[0].errorType, errorInfo.type, "Error type should be as expected")
            XCTAssertEqual(events[0].eventParams[0].errorMessage, errorInfo.message, "Error message should be as expected")
        } else {
            XCTAssertEqual(events[0].eventParams[0].eventType, "im", "Event Type should be as expected")
        }
    }
}
