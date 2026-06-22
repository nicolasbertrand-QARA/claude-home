---
name: project-reef-monitor-infoplist-version
description: "When bumping reef-monitor version, must edit ios/reefmonitor/Info.plist literals directly — pbxproj MARKETING_VERSION alone is ignored"
metadata: 
  node_type: memory
  type: project
  originSessionId: 42758dc1-0423-42c3-a7ff-5705aa7cdf73
---

For every reef-monitor version bump that goes through xcodebuild archive, update **both**:

1. `ios/reefmonitor.xcodeproj/project.pbxproj` — `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (Debug + Release configs)
2. `ios/reefmonitor/Info.plist` — `CFBundleShortVersionString` and `CFBundleVersion` (hardcoded literals, NOT `$(MARKETING_VERSION)` variables)

**Why:** Expo's prebuild generates the Info.plist with the version values baked in as literal strings rather than build-setting references. So `xcodebuild archive` reads the literal Info.plist value and ignores the MARKETING_VERSION setting. Caused a failed archive + upload cycle on v1.4.0 (Apple rejected with "CFBundleShortVersionString [1.3.0] must contain a higher version than the previously approved [1.3.0]").

**How to apply:** During [[ship-ios]] for reef-monitor, after bumping `app.json`, immediately also update Info.plist via Edit (read first, then replace both string values). The /ship-ios skill's "Step 3: Regenerate Native Project" via `expo prebuild --clean` would also fix this but loses the manual pbxproj edits (DEVELOPMENT_TEAM, signing settings) — direct Info.plist patching is faster.
