import Foundation
import XCTest

final class BrowserAddressTests: XCTestCase {
    func testAddressAndSearchPreserveUserInput() throws {
        XCTAssertEqual(try SourceValidation.browserURL(" example.com/watch?v=1 ").absoluteString,
                       "https://example.com/watch?v=1")
        let query = "Türkçe video & müzik + fotoğraf #1?"
        let url = try SourceValidation.browserURL(query)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "q", value: query)])
    }

    func testBrowserRejectsInsecureOrCredentialBearingURLs() {
        for value in ["", "  ", "http://example.com", "file:///tmp/test", "https://user:password@example.com"] {
            XCTAssertThrowsError(try SourceValidation.browserURL(value), value)
        }
    }
}
