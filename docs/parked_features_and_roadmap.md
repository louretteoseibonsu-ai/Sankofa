# Sankofa Twi — Parked Features & Development Roadmap

_Last updated: 30 July 2026 · Reflects the code on `main` (post build 21)._

This is the single register of everything that's been **started-and-shelved**,
**spec'd-but-unbuilt**, or **deliberately deferred**, plus a phased plan for
working through it. Each parked item is grounded in the actual codebase (the
flag, stub, or TODO that marks it), so nothing here is guesswork.

---

## Part 1 — Parked features register

| # | Feature | State today | Where it lives in code | Blocker / why parked |
|---|---------|-------------|------------------------|----------------------|
| 1 | **In-app community** (Ghanaian recipes, meetups, movie/concert nights, book & film recs, local cultural-events feed) | Not started — spec only | — | Deferred by you to a dedicated planning session. Needs backend, UGC storage, and **moderation** before it can ship. |
| 2 | **Real billing / in-app purchase** | Stubbed | `config.dart` `kBillingEnabled = false`; `upgrade_screen.dart` + `pedis_store.dart` show "coming soon"; `auth_service.setPremium` is a placeholder | Needs `in_app_purchase` + **server-side receipt verification** before money can change hands. |
| 3 | **Push notifications / daily streak nudges** | No-op stub | `services/notification_service.dart`; `firebase_messaging` commented out in `pubspec.yaml` | Needs Firebase **Blaze** plan + a `sendDailyNudges` Cloud Function + Cloud Scheduler. |
| 4 | **The Nana Line** ("Wisdom on demand", premium) | Brief only | `docs/brief_the_nana_line.md` | Unbuilt. Sits behind billing (Phase 1). |
| 5 | **Drum & Tone Trainer** ("Twi is music", premium) | Brief only | `docs/brief_drum_and_tone_trainer.md` | Unbuilt. Audio-heavy; sits behind billing. |
| 6 | **Sankofa Lens monetization** | Built, but free | `config.dart` `kLensFreeDuringTesting`; Lens screen live | Feature works; the **paywall** is parked until billing is live. |
| 7 | **Grammar-aware sentence translation** (build-the-sentence English reveal) | Reverted | `lesson_drills.dart` `BuildDrill` (gloss removed, commit 4ccb6fb) | Literal glossary lookup left grammar particles ("me" → "I") untranslated. Needs a proper translation source per unit, not a word-by-word gloss. |
| 8 | **Final character & landmark art** (Super Family avatars, journey landmark heroes) | Placeholders rendering | `data/avatar.dart`, `data/landmark.dart`, `widgets/avatar_badge.dart`, `widgets/landmark_sheet.dart` (`_placeholder()`) | Sculpted placeholders in place; final commissioned art "lands later". |
| 9 | **Tro-tro cosmetic / horn machinery removal** (tech debt) | Retired from UI, code lingers | `data/trotro_cosmetics.dart`, `widgets/composable_trotro.dart`, `tintable_trotro.dart`, `mascot.dart`, `trotro_mascot.dart`, `screens/customization_shop_screen.dart` (still routed from `journey_screen` + `progress_dashboard`), `trotro_rally_screen.dart` | Cosmetics were retired for the pedis model; the old classes/routes remain. Clean removal was started then paused for a bug. **Preserve `CosmeticState` + `equipAvatar`.** |
| 10 | **Legal document finalization** | Placeholder text | `screens/legal_screen.dart` — `[BRACKETED]` fields | Privacy Policy / T&Cs need company name, contact, jurisdiction filled before store submission. |
| 11 | **Monitoring: Crashlytics / Analytics / Performance** | Not wired | (recommended in `docs/launch_and_maintenance_roadmap.md`) | Launch-hygiene; add once, then read dashboards. |
| 12 | **iOS / TestFlight** | Android-only | — | Needs a Mac + Apple Developer account (~$99/yr). Parked until Android is solid. |

---

## Part 2 — Phased roadmap

Sequenced for a solo developer, launch-blockers first, then revenue, then the
features that grow and retain users. Each phase should ship on its own branch and
be beta-tested before the next begins.

### Phase 0 — Launch blockers (now → first public beta)
The goal is a clean, shippable Android build. Nothing new; just close gaps.

- Fill the `[BRACKETED]` legal placeholders (item 10).
- Wire **Firebase Crashlytics** (+ Analytics) — item 11.
- Finish the **tro-tro / cosmetics teardown** (item 9) so the codebase is clean
  and `CustomizationShopScreen` is no longer routed. Preserve `CosmeticState` +
  `equipAvatar`.
- Ship the Android beta via **Firebase App Distribution** to 5–10 testers.

_Exit criterion: Crashlytics quiet, testers installed, no dead cosmetic routes._

### Phase 1 — Turn on the money (post-beta)
- Integrate **`in_app_purchase`** with **server-side receipt verification**
  (item 2).
- Flip `kBillingEnabled = true` and `kLensFreeDuringTesting = false`; enforce the
  paywall on premium courses (already gated) and **Sankofa Lens** (item 6).
- Verify the plan selector + pedis top-up flows end-to-end with a real sandbox
  purchase.

_Exit criterion: a test account can subscribe, get Premium, and cancel via the
store._

### Phase 2 — Retention engine
The streak system you just shipped (freeze calendar + 7/14/21/28-day goals) is the
hook; notifications are what bring people back to it.

- Build **push notifications / daily streak nudges** (item 3): Blaze upgrade,
  `sendDailyNudges` Cloud Function, re-enable `firebase_messaging`.
- Tie nudges to streak-at-risk state and committed goals.

_Exit criterion: a user who misses a day gets a timely, tasteful nudge._

### Phase 3 — Community (the deferred #6 — own planning session)
Large enough to need its own scoping. Suggested MVP sequencing to de-risk
moderation:

1. **Curated cultural-events feed** (read-only, admin-posted) — low moderation
   burden, immediate value.
2. **Recommendations** (books/films) as structured, reactable lists.
3. **User-generated content** (recipes, meetup posts) — only after a moderation
   plan (report/flag, block, review queue) exists.

_Start with a dedicated planning doc before any code._

### Phase 4 — New premium modules
With billing live and retention working, add depth that justifies the subscription.

- **The Nana Line** (item 4) — build from `brief_the_nana_line.md`.
- **Drum & Tone Trainer** (item 5) — build from `brief_drum_and_tone_trainer.md`.

### Phase 5 — Content & craft polish
Ongoing, parallelizable with the above.

- **Grammar-aware translations** for build-the-sentence (item 7) — source proper
  per-unit English, replacing the reverted gloss.
- **Final avatar & landmark art** (item 8) as commissions land.
- Expand the course catalog; keep the twi review pipeline (`twi_review_units_*`)
  moving.

### Later — iOS
- **TestFlight / App Store** (item 12) once Android is stable and revenue proves
  the case for the Mac + Apple Developer cost.

---

## Suggested near-term order (next 3 things)
1. **Tro-tro / cosmetics teardown** (Phase 0) — unblocks a clean build and removes
   dead routes you'll otherwise keep tripping over.
2. **Crashlytics + legal placeholders** (Phase 0) — cheap, and both are hard
   launch requirements.
3. **Billing spike** (Phase 1) — the single feature that unlocks every premium
   module downstream.
