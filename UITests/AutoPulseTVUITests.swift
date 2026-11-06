import XCTest

final class AutoPulseTVUITests: XCTestCase {
    @MainActor
    func testCreateSourceAndCaptureScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        capture("01-library")
        app.buttons["addSource"].tap()
        app.buttons["importLink"].tap()
        XCTAssertTrue(app.textFields["sourceTitle"].waitForExistence(timeout: 5))
        app.textFields["sourceTitle"].tap()
        app.textFields["sourceTitle"].typeText("Kendi videom")
        app.textFields["sourceURL"].tap()
        app.textFields["sourceURL"].typeText("https://example.com/my-video.mp4")
        capture("02-add-source")
        app.buttons["saveSource"].tap()
        app.buttons["Bitti"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Kendi videom"].waitForExistence(timeout: 5))
        capture("03-saved-source")
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("03b-landscape-library")
        XCUIDevice.shared.orientation = .portrait
        app.tabBars.buttons["Ayarlar"].tap()
        capture("04-information")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Kütüphane"].tap()
        XCTAssertTrue(app.staticTexts["Kendi videom"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testStoreScreenshots() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        for page in ["library", "import", "discover", "photo"] {
            app.launchArguments = ["-store-page", page]
            app.launch()
            XCTAssertTrue(app.otherElements["storeScreenshotReady"].waitForExistence(timeout: 90))
            if page == "library" { XCTAssertTrue(app.buttons["media-Göl kenarında"].waitForExistence(timeout: 15)) }
            if page == "photo" {
                XCTAssertTrue(app.buttons["photoAirPlay"].waitForExistence(timeout: 15))
                XCTAssertTrue(app.otherElements["photoImageReady"].waitForExistence(timeout: 15))
            }
            capture("store-\(page)")
            app.terminate()
        }
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
