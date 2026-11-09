# Parked CarPlay browser

The app now declares an additional `UIWindowSceneSessionRoleCarPlay` scene. Its
`CarBrowserSceneDelegate` creates an independent WebKit browser on the vehicle
window. The existing template scene and audio entitlement are preserved.

This role is not a public Swift scene-role constant. The technique is demonstrated
by the independently maintained [Cafari Lite implementation](https://github.com/rPlayAI/cafari-lite).
It is OS/profile dependent, not a guaranteed public CarPlay browser API. CarTV and
APTV source code was not available for comparison; their internals are not assumed.
The implementation here was written independently, without copying their code.

## Use

Grant location access on iPhone. With the vehicle stopped, ten seconds of recent,
accurate speed observations below 0.3 m/s enable the explicit parked confirmation.
Confirm only after parking. Missing/stale/invalid location or movement locks the
browser, removes its web view and stops page/media playback. Returning from an
inactive scene requires a new confirmation. GPS cannot establish transmission gear
or distinguish parking from a stop at a traffic signal; this is a location-based
gate plus driver confirmation, not a verified vehicle Park signal.

Use the existing site shortcuts on the car. For text entry, open a page in the
phone browser and tap the car icon to send its URL to the connected browser.
Phone and vehicle have separate web views. A URL handoff does not transfer a live
video session, form contents, scroll position or site-specific application state.

## Signing and verification

The repository currently uses the audio entitlement based on account-specific
Apple guidance recorded in CARPLAY.md. It has deliberately not been combined with
the video entitlement. The raw window role may require a different Apple-approved
profile: the reference project reports a video entitlement requirement, with
additional account-specific audio requirements. Those claims do not establish
what this account permits. Confirm the required window-role entitlement with Apple
and inspect the actual signed profile before promising browser availability.

Generate with `xcodegen generate`, build/test with Xcode, then install the signed
build on a physical iPhone and connect to a vehicle. Check the `CarBrowser` log for
`Car browser window connected`. If only the standard template scene appears,
the browser window role has not been delivered by iOS; changing tab titles cannot
fix that. Verify denied location, stale fixes, start/stop, disconnect/reconnect,
phone URL handoff, site login, audio stopping on lock, and DRM behavior on hardware.

Windows validation checks Swift syntax and parses configuration; it does not
compile against the Apple SDK or prove on-vehicle availability or App Review acceptance.

## Always-visible browser entry

The standard template interface now includes Keşfet with the same built-in site
shortcuts as iPhone. Groups remain accessible through the library navigation bar.
Entries stay selectable to explain the current lock instead of disappearing.
The template scene and browser window share CarBrowserParkGate.shared; monitoring
starts on the template connection even when no browser window has arrived.
Repeated start calls no longer reset the observation period.

CarBrowserParkGate.browserEnabled requires stationary AND explicit confirmation.
Shortcut URL handoff additionally requires CarBrowserLink.connected. No shortcut
creates a web view in the template scene or forces an unsupported window role.
When iOS does not supply the browser window, Keşfet reports that separately from
movement or location problems. This change does not establish that the signed
profile supports that window role. Physical-device verification is still needed.
