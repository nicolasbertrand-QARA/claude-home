---
name: Apple Developer ID signing — Ulysse / LaserDash
description: Developer ID cert + notary profile for signing Ulysse's Godot games for macOS distribution
type: reference
originSessionId: c8debd2c-c1de-47ea-8154-dedbb7fedd03
---
For signing/notarizing macOS builds of Ulysse's games (LaserDash, future titles):

- **Developer ID Application identity**: `Developer ID Application: Nicolas Bertrand (MS3V6TWCPK)`
- **Team ID**: `MS3V6TWCPK` (Nicolas Bertrand personal Apple Developer account — distinct from Theodo's `TJY8T22XSH` Apple Development cert)
- **notarytool keychain profile**: `laserdash-notary` (already stored — use `--keychain-profile "laserdash-notary"`)
- **Bundle ID convention**: `local.ulysse.<gamename>` (set in Godot export preset)

Standard sign + notarize + DMG flow:
1. Codesign .app: `codesign --force --options runtime --timestamp --entitlements entitlements.plist --sign "Developer ID Application: Nicolas Bertrand (MS3V6TWCPK)" <App>`
2. Zip with `ditto -c -k --sequesterRsrc --keepParent`, submit with `xcrun notarytool submit ... --keychain-profile laserdash-notary` (use `--no-wait` + poll loop — `--wait` client-times-out after ~25 min on slow Apple queues even when submission is fine)
3. `xcrun stapler staple <App>`
4. Build DMG with `hdiutil create -volname ... -srcfolder <staging> -format UDZO`, sign DMG, notarize+staple DMG
5. Verify: `spctl -a -t open --context context:primary-signature -vv <dmg>` should say "accepted, source=Notarized Developer ID"

Godot entitlements (hardened runtime needs these or the app crashes on launch):
- `com.apple.security.cs.allow-jit` = true
- `com.apple.security.cs.allow-unsigned-executable-memory` = true
- `com.apple.security.cs.disable-library-validation` = true
