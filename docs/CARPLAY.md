# CarPlay video integration

## Two explicit builds

`xcodegen generate` builds the iPhone/iPad application with direct video playback and AirPlay. It makes no CarPlay entitlement request.

`xcodegen generate --spec project-carplay.yml` additionally compiles the native CarPlay scene, declares the video entitlement, and requires iOS 27+. The Apple account and provisioning profile must already be authorized for that entitlement. Merely placing the entitlement in a file does not grant it.

The CarPlay source code has not been compiled with an Apple SDK or tested in a vehicle in this environment. It is an integration implementation awaiting validation, not evidence that CarPlay video works on an arbitrary vehicle.

## Rendering and transport

- Content selection uses CPListTemplate / CPListItem. CarPlay owns layout, resolution, orientation and input presentation. The app doesn't crop or mirror the iPhone display.
- CPSessionConfiguration.supportsVideoPlayback checks receiver capability. It is not a measurement of vehicle movement or permission to show video at that instant.
- List items declare CPPlaybackConfiguration with video preferred presentation. Selected items feed the shared AVPlayer. System video presentation and controls own the external playback experience.
- AVPlayer allows external playback and automatic external playback while an external screen is active. No custom video encoder, screen capture or framebuffer transport exists.
- Playback pause/resume buttons are native template buttons. Disconnect records the position and stops the session.
- Unsupported receivers receive an explanation. Actual video availability and audio fallback remain under the system and vehicle's control.

## Browser and latency limits

Safari content is only displayed on iPhone/iPad. No approved general-purpose CarPlay web browser API was established by this research. The app does not conceal video, impersonate another app category or bypass motion restrictions.

No fixed end-to-end delay is promised. Measure on real hardware: startup time, A/V synchronization, Wi-Fi or wired connection behavior, interruptions, AirPlay disconnect/reconnect, seeking, aspect fit, system full-screen behavior and portrait/landscape head units. API integration does not prove those results.

## Sources

- https://developer.apple.com/videos/play/wwdc2026/212/
- https://developer.apple.com/documentation/carplay/cplistitem
- https://developer.apple.com/documentation/carplay/cpplayableitem
- https://developer.apple.com/documentation/carplay/cpplaybackconfiguration
- https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
- https://developer.apple.com/documentation/avfoundation/avplayer/usesexternalplaybackwhileexternalscreenisactive

After choosing the CarPlay build, update store and review metadata to describe that exact tested build. Existing store drafts describe the default iPhone build.
