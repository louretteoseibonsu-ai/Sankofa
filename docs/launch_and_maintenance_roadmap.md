# Sankofa Twi — Launch & Maintenance Roadmap

A plain-English project plan for moving from **build mode** to **launch &
maintenance mode**. Written for a solo, novice developer on your existing stack:
**Flutter + Firebase + GitHub + a Render backend**. Where money or store policy
is involved, treat figures as approximate and **verify the current numbers** when
you set up the account — they change.

> **Do this week (don't wait for "perfect"):** get an Android test link to 5–10
> people. Ten real testers beat a month of solo polishing. Everything else below
> supports that loop.

---

## Pillar 1 — Maintenance for a novice developer

### A. See problems without being a full-time engineer
Wire up monitoring **once**, then just read dashboards.
- **Firebase Crashlytics** — automatic crash reports with the exact line that
  failed. Add the `firebase_crashlytics` package; turn on email alerts for new
  crashes. This is your #1 tool.
- **Firebase Analytics** — see which screens people use, where they drop off.
- **Firebase Performance Monitoring** — flags slow screens/network calls.
- **Render dashboard** — logs + uptime for your Khaya/translate backend. Turn on
  failure alerts; note the free tier sleeps when idle (the "server waking up"
  delay your app already handles).
- **Store dashboards** — Play Console "Android vitals" (crashes/ANRs) and your
  reviews inbox.

> Rule of thumb: if Crashlytics is quiet and your reviews are calm, you're fine.

### B. The standard "health check" routine
| Cadence | Do this |
| --- | --- |
| **Weekly (15 min)** | Skim Crashlytics for new crashes; read new store reviews; glance at Render logs. |
| **Monthly (1–2 hrs)** | `flutter pub outdated` → update safe (minor/patch) deps; run `flutter analyze` and `flutter test`; check Firebase + Render usage/billing; confirm backups. |
| **Quarterly** | Upgrade the Flutter SDK; do bigger dependency bumps one at a time; test on a real device; review the KGP/plugin warnings. |
| **As needed** | Security: rotate any leaked keys; review Firestore rules after feature changes. |

Key commands (run in the `app/` folder):
- `flutter pub outdated` — what's behind.
- `flutter pub upgrade` — safe updates (respects version limits).
- `flutter analyze` — finds code problems before users do.
- `flutter test` — runs your tests.
- `flutter build appbundle` — the file you upload to Google Play.

### C. Use GitHub so you never break your work
- **`main` is sacred.** It should always build. Don't commit straight to it.
- **One change = one branch.** `git checkout -b fix-lens-audio`, make the change,
  push, open a Pull Request, merge into `main`. If a change breaks something, you
  just don't merge it.
- **Commit small and often** with clear messages ("Fix: audio replays no longer
  charge a credit").
- **Tag every store build.** When you ship version 1.0.0 to the store, create a
  GitHub **Release/tag** `v1.0.0` matching the `version:` in `pubspec.yaml`. Now
  you can always get back to exactly what users have.
- **Never commit secrets.** Keep your Android signing keystore and any API keys
  out of GitHub (use `.gitignore`). If a key ever lands in a commit, rotate it.
- **Protect `main`** (GitHub → Settings → Branches): require a PR before merging.

---

## Pillar 2 — Distribution & beta testing

### A. Get an Over-The-Air (OTA) test link
**Android (do this first — it's your platform):**
- **Firebase App Distribution** (already in your Firebase project, free).
  1. `flutter build apk --release` (or `appbundle`).
  2. Upload the file in Firebase Console → App Distribution (or via CLI).
  3. Add testers by email / create a group; they get a link + install steps.
  4. Re-upload for each new build; testers are notified automatically.
- Alternative: **Google Play "Internal testing"** track — same idea, and it
  doubles as practice for the real store submission.

**iOS (later, only if you go to iPhone):** **TestFlight** — requires an **Apple
Developer account (~$99/yr)** and a **Mac** to build. Skip until Android is
solid.

### B. Gather feedback that tells you what to fix
- Make a short **Google Form** and pin the link in your testers' chat. Ask
  specific, answerable questions, e.g.:
  - What were you trying to do when something felt confusing?
  - Did anything crash or look broken? (screenshot?)
  - What's the one thing you'd fix first?
  - 1–5: how likely are you to keep using it? Why?
  - Device + Android version.
- Add an in-app **"Send feedback"** link (mailto `sankofa@aparato.ai`) so it's one
  tap.
- **Triage weekly:** group feedback into Bugs / Confusing / Requests. Fix bugs
  first, then the most-repeated confusion. Ignore one-off opinions early on.

---

## Pillar 3 — Payment gateway integration

### A. Recommended path: RevenueCat (don't build your own billing)
For digital subscriptions in a mobile app you **must** use the stores' billing
(Apple/Google) — you can't use Stripe/PayPal for in-app digital goods. **RevenueCat**
sits on top of both and removes ~90% of the pain.
1. Create products in **App Store Connect** and **Google Play Console**:
   - Subscriptions: Premium **monthly** and **annual** (with the 7-day trial).
   - Consumables: your **pedis packs** (100 / 550 / 1200).
2. Create a **RevenueCat** account (free up to a revenue threshold), add your
   products, and define an **entitlement** called e.g. `premium`.
3. In the app, add `purchases_flutter`, show the paywall, and call RevenueCat to
   purchase. Check `premium` entitlement to unlock features.
4. **Wire it to your existing code:** today `kBillingEnabled = false` and
   `AuthService.setPremium()` is a placeholder. Replace the placeholder so that a
   verified RevenueCat entitlement sets `premium: true` in Firestore (RevenueCat
   can call a **webhook** → a Cloud Function → update the user doc). Pedis packs →
   credit pedis on a verified purchase. Then flip `kBillingEnabled` to `true`.
5. Keep the `kLensFreeDuringTesting` flag until this is live; turn it off at launch.

### B. Non-negotiable store requirements (digital goods)
- **Use native IAP** for anything digital (Premium, pedis). No external payment
  links inside the app for digital goods. (Some 2024+ rules loosened this in
  limited regions — verify current policy, but native IAP is the safe default.)
- **Restore purchases** button (you have a placeholder — make it work via
  RevenueCat).
- **Clear disclosure** before purchase: price, billing period, auto-renewal, free
  trial terms, and how to cancel. Link your **Terms** and **Privacy Policy**
  (done — just host them publicly too).
- **Account deletion** path — required by both stores (you have in-app deletion;
  also publish a **web deletion URL**).
- **Store fees:** typically **30%**, dropping to **15%** via Apple's/Google's
  small-business programs (under a revenue threshold) — enrol in those.
- **Accurate store privacy forms** (Play "Data safety", Apple "Privacy labels")
  matching your actual data use.

---

## Pillar 4 — Go-to-market (store launch requirements)

### A. What you need before you can publish
- **Developer accounts:** Google Play (**$25 one-time**); Apple (**~$99/yr**, only
  if iOS).
- **Store listing assets:**
  - App icon (✅ done), a **feature graphic**, and **phone screenshots** (show
    Lens, a lesson, the streak/progress — your most attractive screens).
  - **Short description** (one line) + **full description** with **ASO keywords**
    (e.g. "learn Twi", "Akan language", "Ghana", "Adinkra").
  - Category: **Education**; content rating questionnaire; support email
    `sankofa@aparato.ai`.
- **Compliance:**
  - **Privacy Policy + Terms hosted at public HTTPS URLs** (not only in-app).
  - **Play Data safety** form + **content rating** + **target age** (you set 14+
    for Spain/LOPDGDD).
  - **Permissions justification** (camera = Sankofa Lens).
  - **Account-deletion URL**.

### B. Coordinating the launch
1. **Internal testing** (you) → **Closed beta** (your 5–10, then ~20–50) →
   **Production**.
2. Build the **product page** (assets + descriptions) in Play Console.
3. **Submit for review.** Google is usually hours–days; Apple can be longer and
   stricter — read rejection notes carefully and resubmit.
4. Use a **staged/percentage rollout** on Google Play (e.g. 20% → 50% → 100%) so a
   bad build only reaches some users.
5. **Monitor** Android vitals + Crashlytics + reviews for the first 72 hours; be
   ready to ship a quick fix.

---

## Pillar 5 — Operationalizing success: a 30-day launch calendar

Goal: reach the people who care about Twi/Akan heritage — Ghanaian diaspora,
heritage learners, language-learning communities, travelers to Ghana.

### Pre-launch — Week 1 (Days 1–7): set the foundation
- Send the **Android test link to 5–10 people today** (Firebase App Distribution).
- Turn on **Crashlytics + Analytics**; create the **feedback Google Form**.
- Start a simple **landing page** (one screen: what it is, a screenshot, an email
  signup) — a free tool is fine.
- List the **communities** you'll post in (diaspora groups, Reddit r/Twi /
  r/Ghana, language-learning Discords, your own socials).

### Pre-launch — Week 2 (Days 8–14): polish & prep
- Fix the **top 3 issues** from testers; expand to ~20–50 beta users.
- Produce **store assets** (screenshots, descriptions, feature graphic).
- **Host Privacy/Terms** publicly; complete **Data safety** + content rating.
- Tease on social: short clips of **Sankofa Lens** ("point your camera, learn Twi")
  and the **streak/kente** visuals — they're your most shareable moments.
- Build a small **launch-day list** (emails + people who'll share on day one).

### Launch — Day 15 (or when review clears)
- Move to **Production** with a **staged rollout**.
- **Announce everywhere** the same day: landing page, socials, every community on
  your list, and a personal message to your beta testers asking for an honest
  **review** (early ratings matter a lot).
- Post the **Lens "travel to Ghana" story** — it's your most relatable hook.

### Post-launch — Days 16–30: keep the fire going
- **Daily (first 72h):** watch Crashlytics + reviews; reply to every review;
  hotfix anything broken (staged rollout).
- **Weekly cadence:** ship one small improvement; tell users what changed
  ("You asked, we fixed…") — visible momentum builds trust.
- **Engagement:** lean on what you built — streak reminders, daily quests, and
  drop **new lessons/Lens collections** to give people a reason to return.
- **Measure what matters:** Day-1 and Day-7 **retention** (do people come back?),
  crash-free rate, and review sentiment — not just downloads.
- **Plan the next feature** from real demand (the Nana Line and Drum & Tone
  Trainer briefs are ready when the data points there).

---

## One-page priority order (if you only do this)
1. **This week:** test link to 10 people + Crashlytics + feedback form.
2. **Weeks 1–2:** fix top issues; host legal pages; prep store assets.
3. **Payments:** set up RevenueCat; wire entitlements → `premium`; turn off the
   testing flags.
4. **Submit** to Google Play (internal → closed → production, staged rollout).
5. **Launch + 30 days:** announce, reply to reviews, ship weekly, watch retention.

*Tools that fit your stack: Firebase (Crashlytics, Analytics, App Distribution),
GitHub (branches + releases), RevenueCat (payments), Google Play Console. Add
iOS/TestFlight later only if the audience demands it.*
