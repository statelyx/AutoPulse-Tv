# AutoPulse TV

[![iOS verification](https://github.com/statelyx/AutoPulse-Tv/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/statelyx/AutoPulse-Tv/actions/workflows/ios.yml)

A native iPhone/iPad personal media library, embedded WebKit browser and optional CarPlay video integration.

[Türkçe](README.md) · [Architecture](docs/ARCHITECTURE.md) · [Codemagic setup](docs/CODEMAGIC.md) · [Changelog](CHANGELOG.md)

## Features

- HTTPS direct-media playback with native controls, fullscreen and AirPlay receiver selection.
- Search, favorites, groups and resume positions for supported on-demand content.
- Remote/local M3U import, bounded downloads, URL deduplication and JSON backups.
- Embedded phone browser with navigation controls, progress/error state and Safari fallback.
- Separate CarPlay video specification with native templates and entitlement configuration.

No channels or licensed streaming catalog are supplied.

## Verified development status

[Run 42200973648](https://github.com/statelyx/AutoPulse-Tv/actions/runs/42200973648) built the default app and passed six unit tests and one UI test at commit `2d9be98`, using Xcode 26.6 and an iPhone 17 Pro / iOS 26.5 simulator. [Evidence](docs/verification/2026-11-06-ci.json).

Real-device streaming, AirPlay quality, the optional CarPlay build and vehicle behavior remain unverified. Codemagic account connection, distribution signing, TestFlight and App Store release are pending.

## Build

On macOS with Xcode and XcodeGen:

```sh
git clone https://github.com/statelyx/AutoPulse-Tv.git
cd AutoPulse-Tv
xcodegen generate
open AutoPulseTV.xcodeproj
bash scripts/simulator.sh
```

Default target: iOS 17+. Scheme: AutoPulseTV. Bundle ID: com.statelyxx.autopulsetv. Configure your own signing team for physical devices.

The optional `project-carplay.yml` requires an iOS 27+ SDK, Apple's approved video entitlement and a compatible vehicle. It does not mirror the phone framebuffer. The browser runs on iPhone/iPad; system and receiver rules govern external video availability.

## CI and distribution

GitHub Actions runs the simulator script and publishes logs, screenshots and test results. The repository also includes Codemagic simulator and TestFlight workflows. The signed workflow needs account-specific credentials, profiles and an App Store Connect app record; a successful simulator build is not a store release.

See [CONTRIBUTING.md](CONTRIBUTING.md), [the test matrix](docs/TEST-MATRIX.md) and [CarPlay integration notes](docs/CARPLAY.md). Use the repository issue forms for reproducible bugs and feature proposals.
