---
name: ship-ios
description: Build, upload, and submit an iOS app version to the App Store. Handles version bumping, native project config, archiving, App Store Connect metadata, and review submission. Use when the user says "ship it", "submit to the store", "publish to app store", or "new version".
---

# Ship iOS — App Store Submission Skill

This skill handles the complete workflow for shipping a new iOS version to the App Store: version bumping, native build config, archiving, uploading, metadata updates, and review submission.

## Prerequisites

- Xcode installed with a valid signing identity
- `asc` CLI authenticated (`/opt/homebrew/bin/asc`)
- An Expo/React Native project with an `ios/` directory
- App already created in App Store Connect

## Arguments

The skill accepts an optional version string (e.g., `/ship-ios 1.3.0`). If omitted, it auto-increments the patch version from `app.json`.

## Workflow

Execute these steps in order. Stop and report to the user if any step fails.

### Step 1: Determine Version

1. Read `app.json` to get the current version
2. If a version argument was provided, use it. Otherwise, increment the patch version (e.g., 1.2.0 → 1.2.1)
3. Read the current `ios.buildNumber` and increment it by 1
4. Update `app.json` with the new version and buildNumber
5. Tell the user what version is being shipped

### Step 2: Update Store Descriptions

1. Read the existing `appstore/description_en.txt` and `appstore/description_fr.txt`
2. Ask the user: "What changed in this version?" (use AskUserQuestion with a free text option)
3. Update the description files if features were added
4. Generate `appstore/release_notes_en.txt` and `appstore/release_notes_fr.txt` with what's new
5. Show the release notes to the user for approval

### Step 3: Regenerate Native Project

The native iOS project must match `app.json`. Run:

```bash
cd <project_root> && npx expo prebuild --clean
```

Then fix the Xcode project settings that prebuild resets:

1. **Signing**: Add `DEVELOPMENT_TEAM` and `CODE_SIGN_STYLE = Automatic` to both Debug and Release build configurations in `ios/<appname>.xcodeproj/project.pbxproj`
2. **Version**: Set `MARKETING_VERSION` to the new version in both configs
3. **Build number**: Set `CURRENT_PROJECT_VERSION` to the new build number in both configs
4. **Icon**: Copy `assets/images/icon.png` to `ios/<appname>/Images.xcassets/AppIcon.appiconset/App-Icon-1024x1024@1x.png`

To find the team ID, search the pbxproj for any existing `DEVELOPMENT_TEAM` or check `asc auth` config.

### Step 4: Archive

**IMPORTANT**: `xcodebuild archive` CANNOT run from Claude Code's sandbox. You MUST ask the user to run it via the `!` prefix.

Tell the user to run:
```
! cd <project_root>/ios && xcodebuild -workspace <appname>.xcworkspace -scheme <appname> -configuration Release -destination "generic/platform=iOS" -archivePath /tmp/<AppName>.xcarchive archive
```

Wait for the user to confirm it succeeded (look for `** ARCHIVE SUCCEEDED **`).

### Step 5: Upload to App Store Connect

Tell the user to run the export command:
```
! xcodebuild -exportArchive -archivePath /tmp/<AppName>.xcarchive -exportOptionsPlist /tmp/exportOptions.plist -exportPath /tmp/<AppName>Export
```

Before this, create `/tmp/exportOptions.plist` with:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>TEAM_ID_HERE</string>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
```

Wait for `** EXPORT SUCCEEDED **` and `Upload succeeded`.

dSYM warnings are harmless — ignore them.

### Step 6: Update App Store Connect Metadata

Use the `asc` CLI at `/opt/homebrew/bin/asc`:

```bash
# Get app ID
APP_ID=$(asc apps list 2>&1 | node -e "console.log(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).data[0].id)")

# Check existing versions
asc versions list --app "$APP_ID" --output table

# If a PREPARE_FOR_SUBMISSION version exists, update it:
asc versions update --version-id "VERSION_ID" --version "NEW_VERSION"

# If not, create one:
asc versions create --app "$APP_ID" --version "NEW_VERSION" --platform IOS --copyright "YEAR Owner" --release-type AFTER_APPROVAL

# Update localizations (description + what's new):
asc localizations update --version "$VERSION_ID" --locale "en-US" \
  --description "$(cat appstore/description_en.txt)" \
  --whats-new "$(cat appstore/release_notes_en.txt)"

asc localizations update --version "$VERSION_ID" --locale "fr-FR" \
  --description "$(cat appstore/description_fr.txt)" \
  --whats-new "$(cat appstore/release_notes_fr.txt)"

# Update subtitles if needed (pull → edit → push):
asc metadata pull --app "$APP_ID" --version "NEW_VERSION" --dir /tmp/metadata
# Edit /tmp/metadata/app-info/*.json to add/update subtitle
asc metadata push --app "$APP_ID" --version "NEW_VERSION" --dir /tmp/metadata
```

### Step 7: Attach Build

Wait for the build to appear (may take 5-10 minutes after upload):

```bash
asc builds list --app "$APP_ID" --output table
```

Then attach:

```bash
asc versions attach-build --version-id "$VERSION_ID" --build "$BUILD_ID"
```

### Step 8: Validate

```bash
asc validate --app "$APP_ID" --version "NEW_VERSION"
```

Fix any blocking issues. Warnings about subtitles are non-blocking.

### Step 9: Submit for Review

```bash
TOKEN=$(asc auth token --confirm)

# Create review submission
SUBMISSION=$(curl -s -X POST "https://api.appstoreconnect.apple.com/v1/reviewSubmissions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"type":"reviewSubmissions","attributes":{"platform":"IOS"},"relationships":{"app":{"data":{"type":"apps","id":"'"$APP_ID"'"}}}}}')

SUBMISSION_ID=$(echo $SUBMISSION | node -e "console.log(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).data.id)")

# Add version as submission item
curl -s -X POST "https://api.appstoreconnect.apple.com/v1/reviewSubmissionItems" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"type":"reviewSubmissionItems","relationships":{"reviewSubmission":{"data":{"type":"reviewSubmissions","id":"'"$SUBMISSION_ID"'"}},"appStoreVersion":{"data":{"type":"appStoreVersions","id":"'"$VERSION_ID"'"}}}}}'

# Submit
curl -s -X PATCH "https://api.appstoreconnect.apple.com/v1/reviewSubmissions/$SUBMISSION_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"type":"reviewSubmissions","id":"'"$SUBMISSION_ID"'","attributes":{"submitted":true}}}'
```

Verify the response shows `state: WAITING_FOR_REVIEW`.

### Step 10: Commit and Push

```bash
git add -A && git commit -m "v<VERSION> — <summary of changes>" && git push
```

### Step 11: Update Documentation

If the project has a `CLAUDE.md`, update it to reflect version changes.

## Common Issues

| Issue | Fix |
|-------|-----|
| `ENABLE_USER_SCRIPT_SANDBOXING` blocks bundle | Set to `NO` in pbxproj |
| `CFBundleShortVersionString` too low | Run `npx expo prebuild --clean` to sync from app.json |
| Icon has alpha channel | Use `sharp().flatten({background: '#f5f2ed'}).png()` |
| Archive fails with signing error | Add `DEVELOPMENT_TEAM` and `CODE_SIGN_STYLE = Automatic` to pbxproj |
| "Entity state invalid" on create version | A PREPARE_FOR_SUBMISSION version already exists — update it instead |
| Build not found after upload | Wait 5-10 minutes for Apple processing |
| xcodebuild sandbox error from Claude Code | Must run via `!` prefix in user's terminal |
