# Sankofa Twi — Fix-It Plan

_A prioritized response to the hard critique. Ordered by impact ÷ effort, for a
solo developer. The single organising idea: **everything that matters right now
defends trust.** Accurate Twi, in a real voice, that loads every time — that is
the product and the moat. Cut or hide anything that doesn't serve it until it's
unimpeachable._

Effort key: **S** ≤ 1 day · **M** 2–5 days · **L** 1–3 weeks · **XL** 1 month+.
`$` = a real cost. "You-time" = your work; "wait" = someone else's time.

---

## Priority at a glance

| # | Fix | Tier | Effort | Cost |
|---|-----|------|--------|------|
| 1 | Human-review the Twi in Courses 1–2 | P0 trust | M + wait | $ reviewer |
| 2 | Native-voiced audio for Courses 1–2 | P0 trust | M | $0 |
| 3 | Make the leaderboard honest | P0 trust | S | $0 |
| 4 | Backend off free-tier + graceful fallbacks | P0 reliability | S–M | ~$7/mo |
| 5 | One deploy remote + real release checklist | P0 reliability | S | $0 |
| 6 | Turn on push notifications (streak nudge) | P1 retention | M | ~$0 (Blaze) |
| 7 | Real billing (unlock the economy you built) | P1 money | L | store fees |
| 8 | Cut/hide the sprawl (Lens, gacha) | P1 focus | S each | $0 |
| 9 | Automate WOTD posting | P2 growth | M | $0 |
| 10 | iOS / TestFlight | P2 platform | L | $99/yr + Mac |

---

## Already done this session (so the baseline is clear)
Bosses now teach before they test (Learn-first phase + alphabet primer); the
heritage boss got a real concept glossary; listen & build drills have a
"can't-listen" fallback; streak calendar + freezes + goals; velvet-dark sweep
across every screen; kalimba combo-rising SFX + soft-wrong; support/translate
hardened with retries, clearer errors, and credit refunds on failure; day-name,
delete-account, and greeting bugs fixed. These are real, but they're polish on
top of the structural gaps below.

---

## P0 — Trust & reliability (stop building features until these are done)

### 1. Human-review the Twi content — Courses 1–2 first
**Why:** `unit_001` ships as `*.example.json` with a visible "Draft content —
pending language review" banner, and its questions have included incoherent
items (a `-ATR` vowel question inside a lineage lesson). One wrong gloss taught
to a diaspora learner is a trust kill. This is #1 for a reason.
**What:** Pay/partner with a fluent Asante Twi speaker to check every headword,
gloss, example, and challenge in the first two courses. Remove the `.example`
files and the `review_required` flag only once reviewed. Build a simple
"report this word" button so learners flag errors.
**Effort:** M you-time to integrate + **wait** on the reviewer (1–2 wks calendar).
**Cost:** reviewer fee.

### 2. Native-voiced audio for Courses 1–2
**Why:** The app promises "learn like family" and delivers a synthetic Khaya
voice — often silence when the backend is down.
**What:** The pipeline already exists (`AudioBundle` + `assets/audio/manifest.json`
are checked before TTS). Use the recording script PDF you already have → get the
clips → drop them in `assets/audio/` and merge the manifest (human entries
override synthetic). I'll write the slice+manifest build script when clips land.
**Effort:** M you-time once recordings arrive. **Cost:** $0.

### 3. Make the leaderboard honest
**Why:** `_kGhosts` seeds 12 invented players. The moment a user notices, every
number in the app loses credibility.
**What:** Either (a) hide the leaderboard until you have real users, (b) label
seeded entries clearly ("Sample pace-setters"), or (c) make it **friends-only**
(you already have invite codes). Cleanest: friends-only + a global "you vs. your
best."
**Effort:** S.

### 4. Backend off free-tier + graceful degradation
**Why:** The core loop depends on one sleeping Render instance + Khaya + Gemini,
all of which failed this week.
**What:** Upgrade Render to a paid always-on tier (~$7/mo) to kill cold starts.
Confirm `KHAYA_API_KEY`/`GEMINI_API_KEY` are set and monitored. Lean on bundled
audio so lessons never depend on a live call. (Retries, fallbacks, and clearer
errors are already in.)
**Effort:** S–M. **Cost:** ~$7/mo.

### 5. One deploy remote + a release checklist
**Why:** You shipped ~45 commits stale because `origin` ≠ the `sankofa` remote
Render builds from, and versionCodes have been inconsistent (2025 vs 25).
**What:** Pick one canonical remote (or mirror-push to both automatically), turn
on Render auto-deploy, and write a 5-line release checklist (bump version, push,
watch the deploy log, smoke-test bot+translate, `ship.sh`). Main tracks the
deploy remote now — finish the consolidation.
**Effort:** S.

---

## P1 — Retention & money (the growth won't compound without these)

### 6. Turn on push notifications
**Why:** Your #1 retention lever (`NotificationService`) is a no-op stub. A
streak nobody's reminded to keep just resets.
**What:** Firebase Blaze plan → re-enable `firebase_messaging` → `sendDailyNudges`
Cloud Function + Cloud Scheduler, tied to streak-at-risk and committed goals
(the data's already there). Ask permission tastefully after the first win.
**Effort:** M. **Cost:** ~$0 at your scale.

### 7. Real billing
**Why:** `kBillingEnabled = false`; pedis can't be bought; Premium says "coming
soon." You've built a whole economy (pedis, shards, blind boxes, credit packs)
with no way to pay — a funnel with no bottom.
**What:** `in_app_purchase` + server-side receipt verification, then flip the
flag and enforce the paywall you already gate. This unlocks everything downstream.
**Effort:** L. **Cost:** store commissions.

### 8. Cut or hide the sprawl
**Why:** Lens (camera ML) and AI Translate are each their own product; every
half-lit feature is another thing that breaks and another thing to review.
**What:** Gate **Sankofa Lens** behind an explicit "Beta" or Premium wall; keep
**Translate** but only with the fallback messaging; hide the **blind-box gacha**
until billing + content are solid. Ruthlessly reduce surface area so the core
loop is what testers actually experience.
**Effort:** S each.

---

## P2 — Growth & platform (once the core is trustworthy)

### 9. Automate WOTD posting
**Why:** Hand-scheduling Instagram posts isn't a growth engine.
**What:** Route B — a daily cron on your Render backend posting via the Instagram
Graph API (needs an IG Business account + Meta app + token; images hosted on
Render). Generates and posts the batches automatically, month after month.
**Effort:** M. **Cost:** $0.

### 10. iOS / TestFlight
**Why:** Android-only halves your reachable diaspora audience; iOS isn't built
and Google Sign-In isn't configured for it.
**What:** Apple Developer account, Xcode build, add the `REVERSED_CLIENT_ID` URL
scheme (I prepped the camera/photo permission strings already), ship to
TestFlight. Follow `docs/ios_setup_walkthrough.md`.
**Effort:** L. **Cost:** $99/yr + a Mac.

---

## The one-sentence version
Spend the next month making **Courses 1 and 2 unimpeachable** — human-reviewed
Twi, your dad's voice, a backend that never embarrasses you, and a daily nudge to
come back — and hide everything else. That is the whole game.
