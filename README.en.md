# AutoPulse TV

[![iOS verification](https://github.com/statelyx/AutoPulse-Tv/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/statelyx/AutoPulse-Tv/actions/workflows/ios.yml)

A native iPhone/iPad personal media library, embedded WebKit browser and CarPlay integration in the same build.

[Türkçe](README.md) · [Architecture](docs/ARCHITECTURE.md) · [Codemagic setup](docs/CODEMAGIC.md) · [Changelog](CHANGELOG.md)

## Features

- HTTPS direct-media playback with native controls, fullscreen and AirPlay receiver selection.
- Search, favorites, groups and resume positions for supported on-demand content.
- Remote/local M3U import, bounded downloads, URL deduplication and JSON backups.
- Embedded phone browser with navigation controls, progress/error state and Safari fallback.
- Unified CarPlay audio/video configuration with native templates.

No channels or licensed streaming catalog are supplied.

## Verified release status

Version 1.1.0 (4) is Testing in the existing internal TestFlight group after a successful signed Codemagic build and App Store Connect upload. No public App Store review was submitted.

[Latest simulator CI](https://github.com/statelyx/AutoPulse-Tv/actions/runs/42227322556) passed 10 unit and 2 UI tests and captured four real app pages on both iPhone and iPad. [Screenshot pack](store/AutoPulseTV-1.1-AppStore.zip) · [Release details](docs/RELEASE-1.1.md).

Files/Photos offline import, full-screen photo zoom/slideshow, still-image AirPlay presentation, PiP, discovery shortcuts and Xtream-compatible playlist import are included. Physical AirPlay/vehicle behavior and the updated unified build remain unverified.

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

One `project.yml` includes iPhone/iPad and CarPlay sources, explicit scene metadata and audio/video entitlements. The app targets iOS 17+; the delegate retains its iOS 27 availability annotation. Signed builds require Apple-authorized App ID capabilities and matching profiles. Unsupported video receivers retain the list in audio mode. The browser runs on iPhone/iPad; system and receiver rules govern video availability.

## CI and distribution

GitHub Actions runs the simulator script and publishes logs, screenshots and test results. The repository also includes Codemagic simulator and TestFlight workflows. The signed workflow needs account-specific credentials, profiles and an App Store Connect app record; a successful simulator build is not a store release.

See [CONTRIBUTING.md](CONTRIBUTING.md), [the test matrix](docs/TEST-MATRIX.md) and [CarPlay integration notes](docs/CARPLAY.md). Use the repository issue forms for reproducible bugs and feature proposals.
