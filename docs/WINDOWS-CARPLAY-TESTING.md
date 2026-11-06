# Windows + iPhone test desk

Checked: 6 November 2026. Available user equipment: Windows x64 PC and iPhone. The PC exposes Intel Wi-Fi and Bluetooth hardware; a successful iPhone/receiver connection has not been demonstrated. No receiver has been downloaded, installed or started by this work.

## TestFlight visibility

Installing an iPhone app through TestFlight does not add CarPlay support. The distributed application must contain the CarPlay scene and the correct Apple-approved signed entitlement. A video-only CarPlay app also needs a connected receiver that supports Video in the Car. A phone installation is not evidence of either condition.

In this repository:

- `simulator`: default phone build and tests; no CarPlay scene.
- `carplay-compile`: compiles project-carplay.yml with Xcode 27.1, without signing. Does not connect a receiver or produce a TestFlight-ready IPA.
- `testflight`: currently defaults to project.yml. Set PROJECT_SPEC to project-carplay.yml only once the account/profile is authorized and a compatible SDK is selected.

After producing a signed IPA, run `python scripts/inspect_ipa.py path/to/app.ipa` to inspect its scene and embedded profile permissions. This script does not validate the code signature or prove receiver behavior.

## Receiver findings

| Candidate | Platform / delivery | What is established | Remaining gap |
| --- | --- | --- | --- |
| PlayPort | macOS server + browser | Its README documents a Mac server; Windows can be a browser screen | Not a standalone Windows-hosted setup |
| WinPlay | Windows installer available, V1.2.5 | Wireless CarPlay UI/audio receiver | Video in the Car capability for our video-only app is not established |
| ChairPlay | Windows portable/setup available, v1.0.7 | Wireless CarPlay, desktop controls, tested OS versions documented | General CarPlay H.264 output does not establish separate media-video handoff support |
| CarCast | Windows version documented | Developer explicitly describes Video in the Car and Windows/iOS 27.2 | No Windows installer asset was found in its public GitHub releases during this check |

Do not confuse decoding the normal CarPlay UI video stream with receiving a movie through Video in the Car. That distinction determines whether our video-only application is exposed and can play media on iOS 27.2.

The separately shared `mustkimkureshi/WinPlay` repository has no published releases at the time of this check. Its download link leads back to the repository. The installer availability above refers specifically to `Roylyl/WinPlay`, not this separate repository.

## Acceptance sequence

1. Compile the CarPlay variant. Fix SDK/type/build issues before device installation.
2. Verify the approved profile and signed build. Obtain a TestFlight build of that variant.
3. Select a receiver with confirmed Video in the Car support and an obtainable Windows package.
4. Review the actual installer and required system changes before installing. No firewall, security, Bluetooth pairing or network settings were changed here.
5. On the desk, connect the iPhone and verify ordinary CarPlay first, then the reported video capability, app icon and video handoff.
6. Run landscape/portrait, reconnect, pause/resume, video-availability change and measured A/V sync cases. Retain sanitized logs, build SHA, receiver version and iOS version.

Until step 5 succeeds, this is a prepared test plan, not a working test bench. Receiver software is separate from AutoPulse TV and is not added to the commercial application's source or binary.

## Primary sources

- https://developer.apple.com/carplay/
- https://developer.apple.com/videos/play/wwdc2026/212/
- https://github.com/youcci/playport
- https://github.com/Roylyl/WinPlay
- https://github.com/mustkimkureshi/WinPlay/releases
- https://github.com/NumberOneBot/ChairPlay
- https://github.com/rPlayAI/carcast-public/blob/main/docs/windows.md
- https://github.com/rPlayAI/carcast-public/releases
