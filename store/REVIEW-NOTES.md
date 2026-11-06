# App Review / Beta Review Notes — new unified build only

Requested entitlements: `com.apple.developer.carplay-audio` and `com.apple.developer.carplay-video`. Both are declared in the app source. Declaration is not proof of Apple approval; verify App ID authorization and signed provisioning before submission. Do not submit build 4: it predates the unified CarPlay build.

AutoPulse TV is a personal media player. It provides no channel/movie catalog, subscription, bundled paid content or streaming-service login bypass. Users import media they own or are authorized to use. No app account or login is required for the local-media review steps. Optional provider credentials are user supplied and are not needed for review.

Video in the vehicle is intended only while parked and when permitted by the operating system and compatible receiver. The app does not bypass motion restrictions or mirror the phone browser. CarPlay uses native list templates. Receivers without video capability retain the list with audio preferred presentation and a Ses label. A photo presentation uses a silent still-image video clip and is not a phone-screen mirror. Physical vehicle compatibility has not yet been verified.

## No-login test steps

1. Launch the new build on iPhone or iPad. The initial library may be empty; no production demo catalog is bundled.
2. Tap +, then Dosyalar'dan ekle. Choose a reviewer-owned playable MP4/MOV from Files. Return to the library and play it.
3. Import a reviewer-owned JPEG/PNG from Files or the system Photos picker. Open it full screen, zoom, start/stop the slideshow and close it.
4. Favorite a source, filter video/photo and reopen the app to verify persistence.
5. Open Keşfet and enter an HTTPS website. The browser stays on iPhone/iPad. No website login is required by the app.
6. On an authorized CarPlay simulator or compatible parked vehicle, open AutoPulse TV. Check the source list and Duraklat/Oynat controls. Without video capability, expect AutoPulse TV — Ses and audio presentation; a silent photo clip has no audible content.
7. If the receiver supports Video in the Car and system policy permits it while parked, select the imported video. Do not infer vehicle support from phone AirPlay availability.

No fixed latency, universal vehicle compatibility or third-party DRM playback is claimed. Build-specific review notes must identify the new successful build number and any remaining entitlement/hardware limitation.


## Account-specific entitlement update

Apple approval correspondence supplied on 2026-11-06 states that audio and video entitlements must not be combined. This app uses only `com.apple.developer.carplay-audio` for mixed audio/video and visibility on audio CarPlay receivers. Enable CarPlay Audio App on com.statelyxx.autopulsetv and regenerate development/App Store profiles. Do not enable or sign this build with CarPlay Video App. Actual video presentation remains receiver/system dependent. Portal/profile updates and new TestFlight upload still require verification. This supersedes earlier dual-entitlement instructions in this document.
