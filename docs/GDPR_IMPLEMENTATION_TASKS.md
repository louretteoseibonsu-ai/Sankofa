# GDPR / LOPDGDD Implementation Tasks — Sankofa Twi

A technical roadmap to make the app's data handling match the Privacy Policy &
Terms (Spain / EU launch). This is operational guidance, **not legal advice** —
have a Spanish-qualified lawyer/DPO sign off before launch.

Legend: ☐ = to do · 🟡 = partially in place · ✅ = done

---

## 0. Fill in the placeholders first

The legal text lives in `app/lib/screens/legal_screen.dart` as `kPrivacyPolicy`
and `kTermsAndConditions`. Replace every `[BRACKETED]` value:

- `[COMPANY LEGAL NAME]`, `[NIF / CIF]`, `[STREET, POSTAL CODE, CITY]`
- `[DPO / PRIVACY EMAIL]` (a dedicated privacy inbox, e.g. `privacy@aparato.ai`)
- `[DPO NAME / "Not appointed"]`
- `[ANY OTHER PROCESSORS]` + `[PURPOSE]` (analytics, crash reporting, email, etc.)

> Decide whether you must appoint a DPO. For a small app this is usually **not**
> mandatory unless your core activity is large-scale or systematic monitoring or
> special-category data. Document the decision either way.

---

## 1. Consent — where to put checkboxes

GDPR consent must be **specific, informed, unbundled, and opt-in** (no pre-ticked
boxes). Separate "agree to Terms" from each optional consent.

- ☐ **Sign-up screen** (`login_screen.dart`, register mode): add a **required**
  checkbox (unticked by default) for *"I have read and agree to the Terms &
  Conditions and Privacy Policy"* with tappable links opening `LegalScreen`.
  Block submit until ticked. This documents acceptance of the contract — it is
  **not** a substitute for granular consent below.
- ☐ **Optional profile data** (`profile_screen.dart`, date of birth & gender):
  these are optional already; add a one-line note *"Optional — used to
  personalise your experience"* so the consent context is clear.
- ☐ **Social / pen-pal features** (when built): a **separate opt-in** toggle in
  Profile, defaulting OFF, with its own short explainer. Store the choice and the
  timestamp.
- ☐ **Analytics / crash reporting / marketing** (if added): separate opt-in
  toggles, OFF by default. Do not initialise the SDK until the user opts in.
- ☐ **Record proof of consent**: store, per user, `{consentType, version,
  grantedAt}` in Firestore (e.g. `users/{uid}/consents`). Keep the policy
  version string so you can prove *which* text they agreed to.

---

## 2. AI transparency (EU AI Act + GDPR Art. 13/22)

- ☐ On the **Translate / Twi audio screen**, show a persistent, visible label:
  *"Translations and audio are AI-generated and may be inaccurate."*
- ☐ Add a first-use info sheet explaining that text is sent to **GhanaNLP /
  Khaya** to produce the result, with a link to the Privacy Policy AI section.
- ☐ Do not pre-fill AI fields with personal data; add placeholder guidance
  *"Don't enter sensitive personal information."*
- ☐ Confirm with your AI provider (data processing agreement) whether they
  retain or train on submitted text, and reflect the truthful answer in the
  policy's retention section.

---

## 3. Right of access & portability (DSAR)

- ☐ Add **"Download my data"** in Profile → exports the user's `users/{uid}`
  document + leaderboard entries as JSON (machine-readable = portability).
  - Client can assemble this from existing reads; for completeness use a Cloud
    Function (`exportUserData`) mirroring the `adminDeleteUser` pattern.
- ☐ Provide a fallback email route to `[DPO / PRIVACY EMAIL]` and commit to the
  **1-month** response deadline (extendable by 2 months for complex requests —
  notify the user if you extend).
- ☐ Add an identity-verification step before fulfilling email-based requests.

---

## 4. Right to erasure ("right to be forgotten") — deletion button

🟡 **Partially in place.** `profile_screen.dart` has *Delete account* →
`AuthService.deleteAccount()`, and the admin panel has a Cloud Function
(`adminDeleteUser`) that removes the Auth login + Firestore records.

- 🟡 **Self-service deletion exists** — keep the confirm dialog (done).
- ☐ Make deletion **complete**: ensure it also removes `leaderboard_weekly/*`
  entries, uploaded avatar files in Storage (`avatars/{uid}.jpg`), and any
  `consents` subcollection. Extend `deleteAccount()` / the Cloud Function.
- ☐ Handle `requires-recent-login` gracefully (re-auth then retry) — already
  messaged in the UI; verify the re-auth path.
- ☐ Document the **legal-hold exception**: billing/tax records you must keep are
  retained per Spanish law even after deletion (already stated in the policy).
- ☐ App-store requirement: Google Play & Apple now require an **account-deletion
  route**, including a **web URL** for users who deleted the app. Create a simple
  web page that initiates deletion or routes to `[DPO / PRIVACY EMAIL]`.

---

## 5. Rectification, restriction & objection

- 🟡 **Rectification**: Profile already lets users edit name, DOB, gender, avatar.
  Add the ability to **change email** (Firebase `verifyBeforeUpdateEmail`).
- ☐ **Objection / restriction**: provide an email route and, for legitimate-
  interest processing (analytics, security), an opt-out toggle where feasible.
- ☐ **Withdraw consent**: every opt-in toggle from Section 1 must be reversible
  in Profile at any time, as easily as it was given.

---

## 6. Data minimisation & security

- ✅ Email/password handled by Firebase Auth (TLS); duplicate-email enforced.
- ✅ Firestore security rules restrict each user to their own document; admin
  access gated by `admins/{uid}` allow-list. **Deploy them**:
  `firebase deploy --only firestore:rules`.
- ☐ Confirm the IP-geolocation call (`ipapi.co`) does **not** persist the IP and
  is only used for currency; state this truthfully (already in policy).
- ☐ Set Firebase data location to an **EU region** (e.g. `eur3`) when creating
  Firestore — choose this at database creation; it cannot be changed later.
- ☐ Lock down Storage rules for avatars (owner-write, public-read or signed URLs
  only as needed).
- ☐ Enable **Firebase App Check** to reduce abuse of your backend/AI endpoints.

---

## 7. Records, processors & breach readiness

- ☐ Maintain a **Record of Processing Activities (ROPA)** (GDPR Art. 30) —
  a simple table of purposes, data, lawful bases, processors, retention.
- ☐ Sign/keep **Data Processing Agreements (DPAs)** with each processor: Google
  Firebase, GhanaNLP/Khaya, ipapi.co, app stores, plus analytics/email if added.
- ☐ Verify **international-transfer safeguards** (SCCs / adequacy) for any
  processor outside the EEA; keep copies.
- ☐ Write a short **breach-response plan**: who is notified, and the **72-hour**
  AEPD notification obligation for qualifying breaches.
- ☐ Consider whether a **DPIA** (Data Protection Impact Assessment) is needed —
  likely yes if pen-pal/social features process messages at scale or involve
  minors.

---

## 8. Minors (LOPDGDD age = 14)

- ☐ Add an **age gate / date-of-birth check** at sign-up; block under-14s (Spain)
  and apply the correct minimum age per country if you expand.
- ☐ Ensure social/pen-pal features have safeguards if any minors (14–17) use the
  app (reporting, blocking, no exposure of precise data).

---

## 9. Store & legal-page hosting

- ☐ Publish the Privacy Policy and Terms at **public HTTPS URLs** (required by
  Apple App Store Connect and Google Play Console) — not only in-app.
- ☐ Complete Apple's **Privacy Nutrition Labels** and Google's **Data Safety**
  form so they match this policy exactly (mismatches cause rejections).
- ☐ Add the policy/terms links to the store listings and the in-app Profile
  (in-app links already wired via `LegalScreen`).

---

## Quick status snapshot

| Area | Status |
| --- | --- |
| Privacy Policy & Terms drafted (Spain/EU, AI, Barcelona) | ✅ in-app |
| Self-service account deletion | 🟡 exists; widen scope |
| Admin hard-delete Cloud Function | ✅ built (deploy needed) |
| Firestore per-user + admin rules | ✅ written (deploy needed) |
| Consent checkboxes (sign-up + granular) | ☐ to build |
| AI transparency labels | ☐ to build |
| Data export (portability) | ☐ to build |
| EU data region + App Check | ☐ to configure |
| ROPA / DPAs / breach plan / DPIA | ☐ documentation |
| Public legal URLs + store privacy forms | ☐ to publish |
