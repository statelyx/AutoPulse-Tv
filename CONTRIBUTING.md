# Development guide

## Environment

Use macOS with Xcode and XcodeGen for iOS builds. The unified app targets iOS 17+. CarPlay sources are included by the same project.yml, with an iOS 27 availability annotation on the delegate. Signed builds require approved CarPlay audio/video capabilities and matching profiles.

```sh
xcodegen generate
open AutoPulseTV.xcodeproj
bash scripts/simulator.sh
```

Keep changes in project.yml rather than editing generated Xcode projects. Generated projects, build products, local tools and signing files are excluded from Git.

## Validation

The simulator script builds the app, runs unit/UI tests and captures an actual screenshot. Inspect build/simulator-build.log, build/simulator-test.log and build/TestResults.xcresult. GitHub Actions publishes these as autopulsetv-verification.

The optional Python validation checks syntax/configuration only:

```sh
python -m pip install -r scripts/requirements-dev.txt
python scripts/validate.py
```

VALIDATION.json is the local static-check result. External CI evidence is recorded separately in docs/verification; do not turn a static check into an Apple SDK or device-test success claim.

## Scope of changes

Describe the behavior change, reproduction steps and relevant tests in a pull request. For playback changes, identify the media type and whether the test used a simulator, physical iPhone, AirPlay receiver or compatible CarPlay vehicle. Use a reproducible public sample or your own licensed content; do not commit private media URLs or signing material.

## Reporting a problem

Use the repository bug-report form. Include the app commit, OS, device/receiver, steps and observed result. Treat website login/DRM restrictions, direct-media failures and CarPlay receiver capability as separate cases.
