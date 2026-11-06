import XCTest

final class ParkPlayUITests: XCTestCase {
    @MainActor
    func testCreateSourceAndCaptureScreens() {
        let app = XCUIApplication()
        app.launch()
        capture("01-library")
        app.buttons["addSource"].tap()
        XCTAssertTrue(app.textFields["sourceTitle"].waitForExistence(timeout: 5))
        app.textFields["sourceTitle"].tap()
        app.textFields["sourceTitle"].typeText("Kendi videom")
        app.textFields["sourceURL"].tap()
        app.textFields["sourceURL"].typeText("https://example.com/my-video.mp4")
        capture("02-add-source")
        app.buttons["saveSource"].tap()
        XCTAssertTrue(app.staticTexts["Kendi videom"].waitForExistence(timeout: 5))
        capture("03-saved-source")
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("03b-landscape-library")
        XCUIDevice.shared.orientation = .portrait
        app.tabBars.buttons["Bilgi"].tap()
        capture("04-information")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Kendi videom"].waitForExistence(timeout: 5))
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
