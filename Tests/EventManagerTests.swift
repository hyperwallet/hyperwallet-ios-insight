import CoreData
@testable import Insights
import XCTest

final class EventManagerTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        EventManager.shared.deleteEvents(before: Date().epochMilliseconds())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        EventManager.shared.deleteEvents(before: Date().epochMilliseconds())
    }

    func testSaveEvent() {
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "There should be 0 record in database")
        EventManager.shared.saveEvent(payload: getMockPayloadData())
        let countAfterSave = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterSave, 1, "There should be 1 record in database")
    }

    func testGetEventsCount() {
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "There should be 0 record in database")
        EventManager.shared.saveEvent(payload: getMockPayloadData())
        let countAfterSave = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterSave, 1, "There should be 1 record in database")
    }

    func testLoadEvents() {
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "There should be 0 record in database")
        EventManager.shared.saveEvent(payload: getMockPayloadData())
        let events = EventManager.shared.loadEvents(before: Date().epochMilliseconds())
        XCTAssertEqual(events.count, 1, "There should be 1 record in database")
        XCTAssertEqual(events[0].actor.trackingVisitId, "1234", "TrackingVisitId should be as expected")
        XCTAssertEqual(events[0].actor.trackingVisitorId, "12345", "TrackingVisitorId should be as expected")
        XCTAssertEqual(events[0].channel, "mobile", "Channel should be as expected")
        XCTAssertEqual(events[0].eventParams.count, 1, "EventParams count should be 1")
        XCTAssertEqual(events[0].eventParams[0].component, "hyperwallet", "Component should be as expected")
        XCTAssertEqual(events[0].eventParams[0].deviceModel, "iPhone", "Device Model should be as expected")
        XCTAssertEqual(events[0].eventParams[0].deviceName, "iPhone XR", "Device Name should be as expected")
        XCTAssertEqual(events[0].eventParams[0].deviceType, "Mobile Phone", "Device Type should be as expected")
        XCTAssertEqual(events[0].eventParams[0].sdkVersion, "1", "SDK Version should be as expected")
        XCTAssertEqual(events[0].eventParams[0].eventType, "im", "Event Type should be as expected")
        XCTAssertEqual(events[0].eventParams[0].screenWidth, 414, "Screen Width should be as expected")
        XCTAssertEqual(events[0].eventParams[0].screenHeight, 896, "Screen Height should be as expected")
        XCTAssertEqual(events[0].eventParams[0].pageTechnologyFlag, "Swift", "Page Technology Flag should be as expected")
        XCTAssertEqual(events[0].eventParams[0].hyperwalletEnvironment, "DEV", "Environment should be as expected")
        XCTAssertEqual(events[0].eventParams[0].orientation, "portrait", "Orientation should be as expected")
        XCTAssertEqual(events[0].eventParams[0].rosettaLanguage, "en", "Language should be as expected")
        XCTAssertEqual(events[0].eventParams[0].hyperwalletIs, "1234", "IS should be as expected")
        XCTAssertEqual(events[0].eventParams[0].product, "hyperwallet-ios-ui-sdk", "Product should be as expected")
    }

    func testDeleteEvents() {
        let initialCount = EventManager.shared.getEventsCount()
        XCTAssertEqual(initialCount, 0, "There should be 0 record in database")
        EventManager.shared.saveEvent(payload: getMockPayloadData())
        let countAfterSave = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterSave, 1, "There should be 1 record in database")
        EventManager.shared.deleteEvents(before: Date().epochMilliseconds())
        let countAfterDelete = EventManager.shared.getEventsCount()
        XCTAssertEqual(countAfterDelete, 0, "There should be 0 record in database")
    }

    private func getMockPayloadData() -> Data {
        return InsightsTestHelper.getDataFromJson("EventPayload")
    }
}
