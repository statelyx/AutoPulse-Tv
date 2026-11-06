import Foundation
import XCTest

final class CarPlayConfigurationTests: XCTestCase {
    func testInfoPlistDeclaresCarPlayScene() throws {
        let manifest = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") as? [String: Any]
        )
        let configurations = try XCTUnwrap(manifest["UISceneConfigurations"] as? [String: Any])
        let scenes = try XCTUnwrap(
            configurations["CPTemplateApplicationSceneSessionRoleApplication"] as? [[String: Any]]
        )
        XCTAssertFalse(scenes.isEmpty)
        let scene = try XCTUnwrap(scenes.first)
        let delegate = try XCTUnwrap(scene["UISceneDelegateClassName"] as? String)
        XCTAssertTrue(delegate.hasSuffix("CarPlaySceneDelegate"), "Unexpected delegate: \(delegate)")
    }

    func testEntitlementsDeclareCarPlayKeys() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let entitlementsURL = repositoryRoot.appendingPathComponent("CarPlay/AutoPulseTV.entitlements")
        let data = try Data(contentsOf: entitlementsURL)
        let entitlements = try XCTUnwrap(
            try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )
        XCTAssertEqual(entitlements["com.apple.developer.carplay-audio"] as? Bool, true)
        XCTAssertNil(entitlements["com.apple.developer.carplay-video"], "Apple account guidance disallows combining audio and video entitlements")
    }
}
