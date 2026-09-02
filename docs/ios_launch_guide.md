# Sankofa Twi — iOS Support Guide

Your iOS project is already scaffolded. This guide covers only what's left, in order,
with the exact values from your project.

**Your project facts**
- Bundle ID: `com.sankofatwi.sankofaTwi`
- Firebase project: `sankofa-twi`
- Min iOS: 13.0 · Orientation: portrait-locked (already set)
- Camera + Photo permission strings: already in `Info.plist` ✅
- `GoogleService-Info.plist`: present ✅ — **but missing the Google Sign-In OAuth client** (fix in Step 2)

---

## 0. Prerequisites (one-time)
1. **Xcode** — install from the Mac App Store (large download). Open it once and let it install components. Then run `sudo xcodebuild -license accept`.
2. **CocoaPods** — `sudo gem install cocoapods` (or `brew install cocoapods`).
3. **Apple Developer Program — $99/year** at https://developer.apple.com/programs/ .
   - Needed for: running on a real iPhone beyond 7 days, TestFlight, and the App Store.
   - NOT needed to run in the **iOS Simulator** (you can test most of the app free there first).

---

## 1. Sanity build in the Simulator (free, do this first)
```
cd ~/SankofaTwi.0.v.0.2/app
flutter pub get
open -a Simulator
flutter run -d iphone      # or: flutter devices  → pick a simulator id
```
Everything except Google Sign-In and the camera (Sankofa Lens) works in the Simulator.
If this runs, your Dart/Flutter side is healthy and the rest is configuration.

---

## 2. Fix Google Sign-In (the one real blocker)
Your `GoogleService-Info.plist` has no `REVERSED_CLIENT_ID`, so Google Sign-In has no iOS
OAuth client. Recreate it and re-download the file:

1. Firebase Console → **sankofa-twi** → ⚙ Project settings → **Your apps**.
2. Confirm the **iOS app** exists with bundle ID `com.sankofatwi.sankofaTwi`. If not, **Add app → iOS** and use that exact bundle ID.
3. Console → **Authentication → Sign-in method** → make sure **Google** is enabled.
4. The simplest way to regenerate everything correctly is the FlutterFire CLI:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure --project=sankofa-twi
   ```
   Pick iOS (and Android) when prompted. This rewrites `GoogleService-Info.plist`
   **with** the `CLIENT_ID` / `REVERSED_CLIENT_ID` and refreshes `firebase_options.dart`.
5. Verify it worked:
   ```
   grep REVERSED_CLIENT_ID ios/Runner/GoogleService-Info.plist
   ```
   You should now see a value like `com.googleusercontent.apps.4018...-abcd`.

---

## 3. Add the Google Sign-In URL scheme to Info.plist
Google Sign-In returns to the app via a custom URL scheme = your **REVERSED_CLIENT_ID**.
Open `ios/Runner/Info.plist` and add this block inside the top-level `<dict>` (paste the
value from Step 2):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Paste your REVERSED_CLIENT_ID here -->
      <string>com.googleusercontent.apps.XXXXXXXX-XXXXXXXX</string>
    </array>
  </dict>
</array>
```
Without this, tapping "Sign in with Google" opens Safari and never comes back.

> Note: if you'd rather ship iOS sooner, you can launch with **email/password sign-in only**
> and add Google later — Steps 2–3 are only required for the Google button.

---

## 4. Install pods
```
cd ~/SankofaTwi.0.v.0.2/app/ios
pod install
```
If it complains about the platform, add `platform :ios, '13.0'` at the top of the generated
`Podfile` and re-run `pod install`. From now on always open **`Runner.xcworkspace`**, never
`Runner.xcodeproj`.

---

## 5. Signing (Xcode)
```
open ~/SankofaTwi.0.v.0.2/app/ios/Runner.xcworkspace
```
1. Select the **Runner** target → **Signing & Capabilities**.
2. Tick **Automatically manage signing**.
3. **Team** → select your Apple Developer team (add your Apple ID under Xcode → Settings → Accounts if it's not listed).
4. Confirm **Bundle Identifier** = `com.sankofatwi.sankofaTwi`.
   - If Xcode says the ID is taken, pick a unique one (e.g. `com.lourette.sankofatwi`) and
     **use the same ID** in the Firebase iOS app + re-run `flutterfire configure`.

---

## 6. Run on a real iPhone
1. Plug in your iPhone, trust the computer.
2. In Xcode pick your device in the top bar → press ▶, or:
   ```
   flutter run -d <your-iphone>
   ```
3. First run: on the phone, Settings → General → VPN & Device Management → trust your
   developer certificate.

---

## 7. Distribute to testers — TestFlight (recommended for iOS)
Firebase App Distribution works for iOS too, but requires collecting each tester's device
UDID and an ad-hoc profile. **TestFlight is far easier** for iOS and is the standard path:

1. App Store Connect → https://appstoreconnect.apple.com → **My Apps → +** → new app, bundle ID `com.sankofatwi.sankofaTwi`.
2. In Xcode: **Product → Archive** (set the top bar device to "Any iOS Device").
3. When the Organizer opens → **Distribute App → App Store Connect → Upload**.
4. In App Store Connect → your app → **TestFlight**: add testers by email (internal testers
   get builds immediately; external testers need a quick Beta App Review the first time).
5. Testers install the **TestFlight** app and get the build there.

CLI alternative once set up: `flutter build ipa` then upload the `.ipa` from `build/ios/ipa/`
via Xcode's Organizer or Transporter.

---

## Checklist
- [ ] Xcode + CocoaPods installed
- [ ] Apple Developer Program ($99/yr) — if going past Simulator
- [ ] `flutterfire configure` re-run → `REVERSED_CLIENT_ID` now in the plist
- [ ] `CFBundleURLTypes` added to Info.plist
- [ ] `pod install` succeeds
- [ ] Signing team set in Xcode
- [ ] Runs on Simulator, then on a real iPhone
- [ ] Archived + uploaded to TestFlight

Already handled for you: iOS folder, Firebase iOS registration, camera/photo permission
strings, portrait lock, min-iOS 13, bundle ID.
