# Sankofa Twi — iOS TestFlight Setup

Goal: give iOS testers a tappable **public install link**. On iOS this means the
**Apple Developer Program ($99/yr) → TestFlight**. There is no free equivalent of
the Android Firebase link.

App facts you'll reuse:
- Bundle ID: `com.sankofatwi.sankofaTwi`
- App name: Sankofa Twi
- Current version/build: `1.1.8 (2041)` — each new upload needs a **higher build number**.

---

## Phase 1 — Enroll in the Apple Developer Program ($99/yr)
1. Go to **developer.apple.com/programs/enroll** and sign in with your Apple ID.
2. Choose **Individual** (fastest — uses your legal name) unless you want the
   listing under a company (Organization needs a D-U-N-S number).
3. Pay the **$99/year**. Approval is usually minutes, occasionally up to ~48h.
   You can't do the next phases until it's approved.

## Phase 2 — Create the app record in App Store Connect
1. Go to **appstoreconnect.apple.com → My Apps → ➕ → New App**.
2. Platform **iOS**; Name **Sankofa Twi**; Primary language **English**.
3. Bundle ID: pick **com.sankofatwi.sankofaTwi**. If it's not in the dropdown,
   first register it at **developer.apple.com → Certificates, IDs & Profiles →
   Identifiers → ➕ → App IDs → App**, description "Sankofa Twi", bundle ID
   `com.sankofatwi.sankofaTwi` (explicit), then come back.
4. SKU: any unique string, e.g. `sankofatwi-ios`. Create.

## Phase 3 — Point Xcode at your paid team
1. Open `app/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Tick **Automatically manage signing**.
4. **Team**: choose your new paid membership (not "Personal Team"). Xcode
   generates a Distribution certificate + provisioning profile automatically.

## Phase 4 — Archive a Release build and upload
1. In the device selector (top bar), choose **Any iOS Device (arm64)** — NOT a
   simulator and NOT your plugged-in phone.
2. **Product → Archive.** This builds Release and can take a few minutes.
   - If it fails on a pod/module error, run `cd app/ios && pod install` first,
     reopen the workspace, and archive again.
3. When the **Organizer** window opens: **Distribute App → App Store Connect →
   Upload → Next** through the prompts (keep automatic signing) → **Upload**.
4. The build uploads to App Store Connect and enters **"Processing"**
   (~10–30 min). You'll get an email when it's ready.

## Phase 5 — Turn on TestFlight
1. App Store Connect → your app → **TestFlight** tab.
2. Once the build shows **"Ready to Test"**:
   - Fill in **Test Information** (what to test, feedback email, etc.) — required
     for external testing.
   - Export compliance won't ask you (we set `ITSAppUsesNonExemptEncryption`).
3. **Internal testers** (instant, no review, up to 100): add yourself and
   teammates under **Internal Testing**. Good for a first smoke test.
4. **External testers + public link** (this is the shareable "tester link"):
   - Create an **External** group, add the build to it.
   - The first external build needs a quick **Beta App Review** (usually < 24h).
   - After approval, enable **Public Link** on the group → copy the
     `https://testflight.apple.com/join/XXXXXXXX` URL.
5. Testers install the free **TestFlight** app, tap your link, and get the beta.
   Builds expire after **90 days**; upload a new build (higher build number) to
   refresh.

## Phase 6 — Put the link on the website
When you have the `testflight.apple.com/join/…` link, tell me and I'll swap the
iOS **"Coming soon"** card on the landing page for a live **"Get app on iOS"**
button + QR pointing at it (and flip the "iOS coming soon" notes).

---

### Quick checklist
- [ ] Apple Developer Program approved
- [ ] App record created in App Store Connect
- [ ] Xcode signing set to the paid team
- [ ] Release archive uploaded, build "Ready to Test"
- [ ] Internal test install works on your iPhone (from the TestFlight app)
- [ ] External group + Beta App Review passed
- [ ] Public TestFlight link copied
- [ ] Website iOS card updated with the link
