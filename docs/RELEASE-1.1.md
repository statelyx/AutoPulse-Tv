# AutoPulse TV 1.1

Implemented: adaptive media grid, video/photo filters, groups, search, favorites tab, source editing, local video/photo import from Files and the system Photos picker (up to 20 items, 500 MB per file), offline copies, full-screen photo zoom and five-second slideshow, still-photo H.264 presentation through the native AirPlay video route, native player Picture in Picture, discovery/search and custom website shortcuts, settings and remote-source JSON backup.

Xtream-compatible HTTPS/HLS playlist import uses the provider's get.php endpoint, with a 2 MB / 2,000 source limit. Account credentials are stored in device-only Keychain items; supported native stream paths are reconstructed at playback. Unsupported external-origin stream paths are skipped. Xtream accounts and local media are excluded from JSON export. Provider content, subscriptions and DRM compatibility are not supplied by the app.

CarPlay remains an opt-in entitlement build. The standard TestFlight build uses native AirPlay. Photo presentation sends a still-image video clip, not the phone UI. Actual vehicle availability is controlled by iOS and the receiver. This release does not establish compatibility with any particular car.

## Store screenshots

Four distinct pages: library, source import, discovery and photo viewer. Debug-only StoreScreenshotFrame wraps the actual SwiftUI views in consistent Turkish explanatory copy. The simulator's native simctl capture takes each page after a debug-only layout/image readiness marker is written. This avoids accessibility snapshot timeouts during store capture. XCUITest separately verifies source creation/persistence and full-screen photo navigation. Original illustrative landscape photos and short still-frame videos are seeded only into an isolated screenshot library. No production library is modified, and no catalog is bundled into Release builds.

Run `bash scripts/simulator.sh` on macOS. Native PNG captures are saved to `build/screenshots/iphone` and `build/screenshots/ipad`. Missing readiness markers fail the script with a diagnostic capture. CI run 42227322556 passed ten unit and two UI tests and captured all eight PNGs. The delivered pack is store/AutoPulseTV-1.1-AppStore.zip. Signed Codemagic build 6aedd645e348ff611c865c01 uploaded 1.1.0 (4), now Testing in the existing internal TestFlight group. Actual AirPlay/vehicle playback requires hardware verification.

## References

- Apple CarPlay: https://developer.apple.com/videos/play/wwdc2026/212/
- System Photos picker: https://developer.apple.com/documentation/PhotosUI/PhotosPickerItem
- File transfer: https://developer.apple.com/documentation/CoreTransferable/FileRepresentation
- Xtream-compatible provider protocol: https://xui.live/docs/api/xtream/
