# Changelog

## 1.1.0 (4) — Internal TestFlight, 2026-11-06

- Local Files/Photos import, offline video/photo grid, groups and favorites.
- Full-screen photo zoom, slideshow, sharing and still-image AirPlay video presentation.
- Native PiP, discovery shortcuts/custom bookmarks and Keychain-backed Xtream-compatible import.
- Ten unit and two UI tests passed; four App Store pages captured for iPhone and iPad.
- Signed Codemagic build uploaded successfully; internal TestFlight group status Testing. Physical AirPlay/CarPlay tests remain pending.


## 1.0.0 — Development

### Added

- SwiftUI iPhone/iPad library with search, favorites and playback position.
- Native AVPlayer playback, fullscreen controls and AirPlay receiver selection.
- HTTPS M3U imports, bounded remote downloads, duplicate filtering and JSON backups.
- Embedded WebKit browser with address bar, back/forward, reload/stop and Safari fallback.
- Optional native CarPlay video scene and entitlement configuration.
- App icon, privacy manifest, XCTest, UI tests, GitHub Actions and Codemagic workflows.

### Improved

- Atomic library storage and protection against overwriting corrupt data.
- Resume handling for live streams, completed videos and invalid media durations.
- Consistent AutoPulse TV product name and AutoPulseTV project/scheme.

### Verified

- GitHub Actions run 42200973648 built the default iOS simulator app successfully.
- Six unit tests and one UI test passed on source commit 2d9be98.
- A real simulator screenshot is included in the README.

### Pending

- Codemagic application connection and first Codemagic build.
- Optional CarPlay build verification, Apple entitlement approval and real-vehicle testing.
- Distribution signing, TestFlight, App Store metadata completion and review.

This is a development version, not an App Store release.
