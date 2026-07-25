# Release Build & Beta Distribution — Step by Step

Get a working test link into testers' hands **this week**, then (later) set up a
real signing key for Google Play. Run all commands from the **`app/`** folder:
`cd ~/SankofaTwi.0.v.0.2/app`.

---

## PART 1 — Beta this week (Firebase App Distribution)

Your release build already signs with the **debug key**, which is fine for App
Distribution (testers install the APK directly, not through the Play Store). No
keystore needed yet.

### Step 1 — Set your version (once per release)
In `app/pubspec.yaml`, set the line:
```
version: 1.0.0+1     # format is name+buildNumber; bump +1 every upload
```

### Step 2 — Build the beta APK
```bash
cd ~/SankofaTwi.0.v.0.2/app
flutter pub get
flutter build apk --release
```
The file lands at:
`build/app/outputs/flutter-apk/app-release.apk`

> If the build complains about **minSdkVersion** (Firebase needs 23+), open
> `android/app/build.gradle.kts` and change `minSdk = flutter.minSdkVersion` to
> `minSdk = 23`, then rebuild.

### Step 3 — Turn on App Distribution (one time)
1. Go to the **Firebase Console** → your `sankofa-twi` project.
2. Left menu → **Release & Monitor → App Distribution** → **Get started**.
3. Copy your **Android App ID** from **Project settings → General → Your apps**.
   It looks like `1:1234567890:android:abcd1234`.

### Step 4 — Upload + invite testers (two ways)

**Easiest (Console, no terminal):**
- App Distribution → **Distributions** → **Upload** the `app-release.apk` →
  add tester emails (or create a group called `beta`) → add release notes →
  **Distribute**. Testers get an email with an install link.

**Repeatable (CLI):**
```bash
# one-time setup
npm install -g firebase-tools
firebase login

# each upload (replace the App ID)
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:1234567890:android:abcd1234 \
  --groups "beta" \
  --release-notes "First beta — please try Sankofa Lens and one lesson."
```
To add testers by email directly, swap `--groups "beta"` for
`--testers "friend1@gmail.com,friend2@gmail.com"`.

### Step 5 — What your testers do
1. They get an email → tap **Accept invitation**.
2. First time only: install the **App Tester** helper (the email walks them
   through it) and enable "install from this source" if Android asks.
3. Install Sankofa Twi → start testing. New builds appear automatically.

### Step 6 — The loop (every improvement)
1. Make the change on a **branch**, merge to `main`.
2. Bump `version:` (e.g. `1.0.0+2`).
3. `flutter build apk --release` → re-run the `distribute` command.
4. Testers are notified. Collect feedback via your Google Form.

---

## PART 2 — Before Google Play production (real signing key)

Google Play requires a **real upload key** (the debug key is not allowed for
production). Do this once, keep the keystore file **safe and backed up** — if you
lose it you can't update your app.

### Step 1 — Create the keystore
```bash
keytool -genkey -v -keystore ~/sankofa-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
It asks for a password and some details — remember the password.

### Step 2 — Tell Gradle about it (kept OUT of GitHub)
Create `app/android/key.properties`:
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=/Users/lourette/sankofa-upload.jks
```

Add to `app/android/.gitignore` (create if missing):
```
key.properties
*.jks
```

### Step 3 — Use it in `app/android/app/build.gradle.kts`
Near the top (inside the file, before `android { ... }`), load the file:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```
Then inside `android { ... }`, add a `signingConfigs` block and point `release`
at it (replacing the current debug line):
```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```

### Step 4 — Build the file Google Play wants
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab` — this `.aab` is what
you upload to the Play Console (Internal testing → Closed → Production).

> Tip: enable **Google Play App Signing** when prompted in the console — Google
> manages the final signing key, and your `sankofa-upload.jks` is just the
> "upload key" (safer, and recoverable if compromised).

---

## Quick reference
| Goal | Command |
| --- | --- |
| Beta APK | `flutter build apk --release` |
| Send beta | `firebase appdistribution:distribute <apk> --app <ID> --groups beta` |
| Play bundle | `flutter build appbundle --release` |
| Check issues first | `flutter analyze` |

**This week's mission:** Steps 1–5 of Part 1 → link to 5–10 people. That's the
whole game right now.
