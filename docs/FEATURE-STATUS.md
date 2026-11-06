# Feature status — 6 November 2026

## Current implementation

- iPhone/iPad: local video/photo imports, HTTPS media URLs, M3U and Xtream imports, favorites, groups, photo viewer/slideshow, JSON backup/restore, native PiP/AirPlay, and the Keşfet WebKit browser with shortcuts.
- CarPlay: native Kütüphane, Favoriler, Gruplar and Oynatıcı tabs; source selection, play/pause/stop, empty-library guidance, loading/errors and receiver video-capability information.
- Signing: only the Apple-approved CarPlay Audio entitlement; the regenerated profile is selected explicitly in Codemagic. Audio and video entitlements are not combined.

## Unfulfilled requirement

The general-purpose web browser is **not implemented on the CarPlay screen**. It runs on iPhone/iPad. The approved template-based CarPlay integration has no verified supported way to embed the existing WKWebView. A parked vehicle does not itself add a browser scene. A browser label or help screen must not be represented as completing this feature.

Video-capable CarPlay playback is distinct from displaying arbitrary websites. Receiver video capability does not prove general-purpose web support. No universal vehicle video compatibility or physical-vehicle test result is claimed.

## Verification

Portable validation checks Swift syntax and YAML/plist/JSON parsing. Xcode simulator unit/UI tests, signed archive/export, Apple processing, internal TestFlight availability, and physical receiver testing are separate results. See the corresponding files in `docs/verification` for observed runs.
