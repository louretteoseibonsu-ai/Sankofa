# Getting Sankofa Twi onto Apple (iOS) — a step-by-step walkthrough

_Written for a solo developer shipping an existing Flutter app to iOS for the
first time. Figures involving money/policy change — **verify current numbers**
when you get there._

App facts (from your repo):
- **Bundle ID:** `com.sankofatwi.sankofaTwi`
- **App name:** Sankofa Twi
- **Version:** `1.0.3+25`
- Firebase iOS config (`GoogleService-Info.plist`) is present.
- Camera + Photo-library permission strings: **already added** to `Info.plist`.
- Push notifications are stubbed off, so **no APNs setup needed** for the first build.

---

## The two hard prerequisites (no way around these)

1. **A Mac with Xcode.** iOS apps can only be built/signed on macOS. You have a
   MacBook Pro — good. Install **Xcode** from the Mac App Store (large, ~10 GB),
   then run it once to accept the license and let it install components.
2. **An Apple Developer Program membership — ~US$99/year.** Required to use
   TestFlight and to submit to the App Store. (Verify the current price.)

Everything below assumes both are in place.

---

## Step 1 — Enrol in the Apple Developer Program
1. Go to developer.apple.com → **Account** → sign in with your Apple ID.
2. Enrol in the **Apple Developer Program** (individual is fine; company/org
   needs a D-U-N-S number and takes longer).
3. Payment + identity verification can take **24–48 hours** — start this first.

## Step 2 — Create the app record in App Store Connect
1. appstoreconnect.apple.com → **My Apps → + → New App**.
2. Platform **iOS**, name **Sankofa Twi**, primary language, and select the
   bundle ID `com.sankofatwi.sankofaTwi` (create it in
   **Certificates, Identifiers & Profiles → Identifiers** first if it's not listed).
3. This record is where TestFlight builds and (later) the store listing live.

## Step 3 — Confirm the Firebase iOS app
1. In the Firebase console, make sure there's an **iOS app** whose bundle ID is
   exactly `com.sankofatwi.sankofaTwi`.
2. Your repo already has `GoogleService-Info.plist`. Open the iOS project in
   Xcode (`open app/ios/Runner.xcworkspace`) and confirm that file is **added to
   the Runner target** (visible in the Runner folder in Xcode's navigator, and
   listed under Target → Build Phases → Copy Bundle Resources). If it isn't,
   drag it in and tick "Runner" as the target.

## Step 4 — Google Sign-In on iOS ⚠️ (the easy-to-miss one)
Your login screen offers **Sign in with Google**, and that needs iOS-specific
config that isn't present yet — your current `GoogleService-Info.plist` has no
`REVERSED_CLIENT_ID`, and `Info.plist` has no URL scheme. Without this, the
Google button will fail on iPhone.

1. In Firebase console → the iOS app → make sure **Google** is enabled under
   Authentication → Sign-in method, then **re-download** `GoogleService-Info.plist`
   (the new one will include a `CLIENT_ID` and `REVERSED_CLIENT_ID`). Replace the
   file in `app/ios/Runner/`.
2. Copy the `REVERSED_CLIENT_ID` value and add a URL scheme to
   `app/ios/Runner/Info.plist` (I can do this edit for you once you paste the
   value — it looks like `com.googleusercontent.apps.1234567890-abc...`):

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>PASTE_YOUR_REVERSED_CLIENT_ID_HERE</string>
       </array>
     </dict>
   </array>
   ```
   (If you'd rather not fiddle with Google Sign-In for the first TestFlight,
   email/password sign-in works without any of this — you can add Google later.)

## Step 5 — Signing in Xcode
1. `open app/ios/Runner.xcworkspace` (the **.xcworkspace**, not `.xcodeproj`).
2. Select the **Runner** target → **Signing & Capabilities**.
3. Tick **Automatically manage signing**, pick your **Team** (your Apple
   Developer account). Xcode creates the signing certificate + provisioning
   profile for you.

## Step 6 — Build the iOS app
From the `app/` folder in Terminal:
```bash
flutter build ipa
```
This produces `build/ios/ipa/*.ipa`. First build is slow (CocoaPods fetches iOS
dependencies). If Pods error, run `cd ios && pod install && cd ..` then retry.

## Step 7 — TestFlight (this is your iOS "tester link")
1. Upload the build: either **Xcode → Product → Archive → Distribute App →
   App Store Connect**, or use **Transporter** (free Mac App Store app) to upload
   the `.ipa`.
2. In App Store Connect → your app → **TestFlight** tab, wait for the build to
   finish "Processing" (a few–30 min).
3. **Internal testing:** add testers by Apple ID (up to 100, no review) — instant.
4. **External testing:** create a group, add testers by email or enable a
   **public link** — this is the shareable "install link" for iOS. External
   builds need a quick Beta App Review (usually < 24h) the first time.
5. Testers install the free **TestFlight** app and open your link/invite.

> Reality check vs Android: there's no equivalent to your Firebase App
> Distribution one-tap link without going through TestFlight + (for a public
> link) that first Beta App Review. That's Apple's process, not a limitation of
> the app.

## Step 8 — App Store submission (later, when you're ready for the public)
Needs: screenshots per device size, description, keywords, support URL, privacy
policy URL (you have one), and the **App Privacy** "nutrition label"
questionnaire (declare camera use for Lens, account data, etc.). Then submit for
App Review.

---

## iOS-specific checklist for THIS app
- [x] Camera usage string (`NSCameraUsageDescription`) — added.
- [x] Photo-library usage string (`NSPhotoLibraryUsageDescription`) — added.
- [ ] Google Sign-In `REVERSED_CLIENT_ID` + URL scheme — **Step 4** (or skip and
      ship with email sign-in first).
- [ ] `GoogleService-Info.plist` added to the Runner target in Xcode — **Step 3**.
- [ ] Signing team selected — **Step 5**.
- [ ] No APNs / push config needed yet (notifications are stubbed off).
- [ ] App icons: Flutter uses `flutter_launcher_icons`; confirm the iOS icon set
      generated (your `ship.sh` runs it for Android; run
      `dart run flutter_launcher_icons` once so iOS gets its icons too).

## Fastest path to an iPhone in a tester's hands
Enrol (Step 1) → create app record (Step 2) → confirm Firebase plist in target
(Step 3) → skip Google Sign-In for now → sign (Step 5) → `flutter build ipa`
(Step 6) → upload + Internal TestFlight (Step 7). Internal testers need no
review, so you can be testing on a real iPhone the same day your enrolment
clears.
