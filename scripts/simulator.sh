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
preferred=[d for d in phones if "Pro Max" in d["name"]]
print((preferred or phones)[0]["udid"])
')
STATE=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["state"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$SIMULATOR_ID")
if [ "$STATE" != "Booted" ]; then xcrun simctl boot "$SIMULATOR_ID"; fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl status_bar "$SIMULATOR_ID" override --time '9:41' --batteryState charged --batteryLevel 100
xcodebuild -project AutoPulseTV.xcodeproj -scheme AutoPulseTV -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee build/simulator-build.log
xcodebuild -project AutoPulseTV.xcodeproj -scheme AutoPulseTV \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/TestResults.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test 2>&1 | tee build/simulator-test.log
xcrun xcresulttool export attachments --path build/TestResults.xcresult --output-path build/phone-attachments
python3 scripts/export_screenshots.py build/phone-attachments build/screenshots/iphone
# Capture a real 13-inch iPad screen for the App Store universal app listing.
IPAD_ID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys,re
devices=json.load(sys.stdin)["devices"]
runtimes=sorted(devices,key=lambda r:tuple(map(int,re.findall(r"\d+",r))),reverse=True)
pads=[d for r in runtimes if "iOS" in r for d in devices[r] if "iPad Pro" in d["name"] and ("13-inch" in d["name"] or "12.9-inch" in d["name"])]
if not pads: sys.exit("No installed 13-inch iPad simulator")
print(pads[0]["udid"])
')
xcrun simctl shutdown "$SIMULATOR_ID"
STATE=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["state"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$IPAD_ID")
if [ "$STATE" != "Booted" ]; then xcrun simctl boot "$IPAD_ID"; fi
xcrun simctl bootstatus "$IPAD_ID" -b
xcrun simctl status_bar "$IPAD_ID" override --time '9:41' --batteryState charged --batteryLevel 100
xcodebuild -project AutoPulseTV.xcodeproj -scheme AutoPulseTV \
  -destination "platform=iOS Simulator,id=$IPAD_ID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/iPadResults.xcresult \
  -only-testing:AutoPulseTVUITests/AutoPulseTVUITests/testStoreScreenshots \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test 2>&1 | tee build/ipad-test.log
xcrun xcresulttool export attachments --path build/iPadResults.xcresult --output-path build/ipad-attachments
python3 scripts/export_screenshots.py build/ipad-attachments build/screenshots/ipad
