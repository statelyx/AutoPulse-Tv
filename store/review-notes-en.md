# Review and TestFlight notes — draft, not submitted

Molaqo is a personal media URL library and player. It does not supply channels, subscriptions or a licensed streaming catalog. No login is required.

Testing: enter a reachable HTTPS HLS (.m3u8), MP4 or MOV URL for content you have permission to use, give it a name, save, then tap the saved source. Use native playback controls. The route picker lists supported external receivers. Swipe a saved entry to delete it and relaunch to verify persistence.

The YouTube button opens the in-app WebKit browser; a Safari view fallback is available. The app does not extract YouTube streams, download YouTube content or promise YouTube playback on CarPlay.

This version has no CarPlay scene or CarPlay entitlement. External playback depends on supported system and receiver capabilities. Do not describe this build as a full CarPlay video browser.

Before review submission: provide an approved stable demo source, reviewer contact from the account, hosted privacy/support URLs, app icon, actual screenshots, age-rating responses and verified privacy disclosures. No contact information or licensing assertion has been invented.

What to test in TestFlight: persistence, invalid links, supported HLS/MP4 playback, playback failures, dismissal stopping playback and actual AirPlay receiver behavior.
