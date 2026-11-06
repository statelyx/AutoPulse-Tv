# CarPlay video integration

## One build

`xcodegen generate` uses project.yml for iPhone/iPad, AirPlay and CarPlay. It includes CarPlay sources, Support/Info.plist scene metadata, and both com.apple.developer.carplay-audio and com.apple.developer.carplay-video entitlements. Apple must authorize these on the App ID; development and App Store profiles must contain them. Entitlement files alone grant no capability.

The app deployment target remains iOS 17; CarPlaySceneDelegate retains @available(iOS 27.0, *). No separate spec or compilation flag is used. The changed unified build still requires Apple SDK and vehicle validation.

## Rendering and transport

- Content selection uses CPListTemplate / CPListItem. CarPlay owns layout, resolution, orientation and input presentation. The app doesn't crop or mirror the iPhone display.
- CPSessionConfiguration.supportsVideoPlayback checks receiver capability. It is not a measurement of vehicle movement or permission to show video at that instant.
- List items declare CPPlaybackConfiguration with video preferred presentation when supported and audio otherwise. Selected items feed the shared AVPlayer. System video presentation and controls own the external playback experience.
- AVPlayer allows external playback and automatic external playback while an external screen is active. No custom video encoder, screen capture or framebuffer transport exists.
- Playback pause/resume buttons are native template buttons. Disconnect records the position and stops the session.
- Receivers without video support retain the source list, use audio presentation and show the Ses label. Actual playback remains under system and vehicle control.

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

Use store/APPSTORE-CONNECT.md and store/REVIEW-NOTES.md for the new build. Build 4 predates this unified CarPlay configuration and must not be submitted as the new build.
