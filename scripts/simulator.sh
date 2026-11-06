#!/bin/bash
# Run on a macOS Xcode host. Captures actual rendered application UI.
set -euo pipefail
mkdir -p build/screenshots
SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
import re
runtimes=sorted(devices, key=lambda r: tuple(map(int,re.findall(r"\d+", r))), reverse=True)
phones=[d for runtime in runtimes if "iOS" in runtime for d in devices[runtime] if "iPhone" in d["name"]]
if not phones: sys.exit("No installed iPhone simulator")
print(phones[0]["udid"])
')
STATE=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["state"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$SIMULATOR_ID")
if [ "$STATE" != "Booted" ]; then xcrun simctl boot "$SIMULATOR_ID"; fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcodebuild -project ParkPlay.xcodeproj -scheme ParkPlay -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee build/simulator-build.log
xcodebuild -project ParkPlay.xcodeproj -scheme ParkPlay \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/TestResults.xcresult \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee build/simulator-test.log
xcrun simctl status_bar "$SIMULATOR_ID" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl install "$SIMULATOR_ID" build/DerivedData/Build/Products/Debug-iphonesimulator/ParkPlay.app
xcrun simctl launch "$SIMULATOR_ID" com.statelyx.parkplay
sleep 3
xcrun simctl io "$SIMULATOR_ID" screenshot build/screenshots/01-library.png
