# Plan Selector — CRO + UI/UX Spec

**Goal:** a minimalist, premium, on-brand subscription selector that makes the
annual ("Legacy") plan the undeniable hero. Mobile-first, thumb-friendly.

**Scope decision:** Sankofa Twi has two *feature* tiers — Free and Premium.
Premium is billed monthly or annually. Rather than fake a third feature tier,
we frame the **annual plan as "Legacy"** (the hero) and use **monthly as the
price anchor**. Same Premium features; the difference is price, commitment, and
a couple of members-only perks. This is cleaner and converts better than three
parallel feature columns on a small screen.

---

## 1. Plan copy

### Free — "Sankofa Start"
- **Tagline:** Begin the journey — free, forever.
- **Pitch:** Learn your first words, symbols, and streaks at no cost, so the
  habit starts before the wallet does.

### Premium (Monthly) — "The Full Cloth"
- **Tagline:** Master the nuance, month to month.
- **Pitch:** Every lesson, AI tool, and symbol unlocked with no long-term
  commitment — flexibility for the curious.

### Legacy (Annual) — "Legacy" ★ HERO
- **Tagline:** Connect to your roots — for good.
- **Pitch:** The full Sankofa experience at the best price, locked in for life,
  for learners serious about reclaiming the language.

> Microcopy under the hero CTA: *"7-day free trial · cancel anytime."*

---

## 2. Feature inventory by tier

| Capability | Free | Premium (Monthly) | Legacy (Annual) ★ |
| --- | :---: | :---: | :---: |
| Foundations + Numbers lessons | ✓ | ✓ | ✓ |
| First 10 Adinkra symbols | ✓ | ✓ | ✓ |
| Streaks, daily quests, leagues | ✓ | ✓ | ✓ |
| Earn & spend pedis | ✓ | ✓ | ✓ |
| **All lessons unlocked** | — | ✓ | ✓ |
| **AI credits/mo** (translate + Lens scans + audio) | 15 | 400 | 400 |
| **Sankofa Lens** (camera → Twi + speak) | uses AI credits | ✓ | ✓ |
| **Top up credits with pedis** | ✓ | ✓ | ✓ |
| **All 60+ Adinkra symbols** | — | ✓ | ✓ |
| **The Nana Line + Drum & Tone Trainer** (rolling out) | — | ✓ | ✓ |
| **Premium Ananse avatar + backstory** | — | ✓ | ✓ |
| Ad-free | — | ✓ | ✓ |
| **Best value — save ~28% (≈3 months free)** | — | — | ✓ |
| **Founder price locked for life** | — | — | ✓ |
| **Legacy badge on profile + leaderboard** | — | — | ✓ |
| **Early access to new features** | — | — | ✓ |

Presentation rule: on the cards, **don't list all rows**. Free shows 3 bullets;
Premium/Legacy show "Everything, plus…" with the 4 highest-desire items
(Lens, AI Translate, Nana Line, all symbols). Full table lives behind a
"Compare plans" text link to avoid cognitive overload.

---

## 2b. Credits & pedis pricing

AI features run on ONE unified pool of **metered monthly credits** —
**1 credit = 1 Khaya API call** (a translation, a Lens scan, OR an audio/TTS
play). This caps per-user backend cost directly. Overage is bought with **pedis**
(soft currency), up to a monthly cap.

**Included per month:** Free 15 · Premium/Legacy 400 AI credits.
**Overage:** 10 credits for 20 pedis. Monthly buy cap: 400.

**Pedis** are earned (lessons, streaks, Lens first-finds) and — when billing is
live — buyable:

| Pack | Pedis | Price (EUR base) | Value |
| --- | --- | --- | --- |
| Starter | 100 | €0.99 | base (~€0.01/pedi) |
| Popular | 550 | €4.99 | ~10% bonus |
| Best value | 1200 | €9.99 | ~20% bonus |

Pedis are virtual items with no cash value; prices localise via CurrencyService
and charge in the app-store currency. All of this is live behind
`kBillingEnabled` (shown as "coming soon" until a payment gateway is wired).

## 3. UI design specification

### Layout (mobile-first)
Single-column **vertical stack** — never side-by-side columns on a phone (text
shrinks, comparison fails). Order top-to-bottom:

```
┌───────────────────────────────┐
│  Akwaaba — choose your path    │  title
│  [ Monthly | Annual •Save 28% ]│  billing toggle (Annual default)
│                                │
│  ╔═══════════════════════════╗ │  ← LEGACY (hero), dark, elevated
│  ║ ★ Most popular            ║ │
│  ║ Legacy                    ║ │
│  ║ Connect to your roots…    ║ │
│  ║ €5.00/mo  (billed €59.99/yr)║ │
│  ║ Everything, plus 4 perks  ║ │
│  ║ [ Start 7-day free trial ]║ │  ← terracotta CTA
│  ╚═══════════════════════════╝ │
│                                │
│  ┌ The Full Cloth ───────────┐ │  ← Premium monthly (quiet)
│  │ €6.99/mo                  │ │
│  │ [ Choose monthly ]        │ │
│  └───────────────────────────┘ │
│                                │
│  Continue with Free →          │  text link, low emphasis
│  Compare all plans · Restore   │
└───────────────────────────────┘
```

Hero sits **top of the stack** (first thing the thumb reaches), Free is a
de-emphasised text link at the bottom — present but never competing.

### Palette & visual hierarchy (Terracotta + grayscale Kente)
Make hierarchy with **weight and contrast**, not many colors. Terracotta is
scarce and earned — it appears almost only on the hero.

| Element | Free | Premium Monthly | Legacy (hero) |
| --- | --- | --- | --- |
| Card surface | White | White | **Charcoal `#2B2B2D`** |
| Border | 1px silver `#E7E9EC` | 1px silver | **2px gold `#E3A92C`** |
| Text | Slate/charcoal | Charcoal | **White / off-white** |
| CTA | Text link only | Outlined (charcoal) | **Filled Terracotta `#E2725B`** |
| Badge | none | none | **Terracotta "Most popular"** pill |

Result: the eye lands on the one dark, gold-edged, terracotta-buttoned card.
Free and monthly visually recede (grayscale), so the hero is the obvious default
without a single aggressive word.

### Billing toggle (minimalist, low cognitive load)
- A **single segmented pill**: `Monthly | Annual`. Two options only.
- **Annual selected by default**, with a small terracotta tag "Save 28%".
- Toggling re-renders the hero price in place (animate the number, ~200ms) — no
  new screen, no modal.
- Show the **per-month equivalent** as the big number (`€5.00/mo`) with
  `billed €59.99/year` as quiet sub-text. Per-month framing shrinks the perceived
  cost. (All prices localised via the existing CurrencyService.)

### Thumb-zone rules
- Primary CTA spans the hero card width, min height 52px, in the lower-middle of
  the screen (natural thumb arc).
- Toggle near the top but still reachable; secondary links (Free, Restore,
  Compare) at the very bottom, small, low-contrast.
- No tappable target under 44×44px. Nothing critical in the top corners.

---

## 4. Conversion psychology

**Anchor effect.** Monthly (€6.99/mo) is the anchor that makes Legacy look like
a steal: present the hero as **€5.00/mo** right beside the monthly card's
€6.99/mo. The annual total (€59.99) is shown small; the per-month number does the
persuading. Optional reinforcement: strike-through the full annual run-rate
(`~~€83.88~~ €59.99`) to make the discount concrete. Monthly effectively becomes a
*decoy* — its job is to make annual obviously smarter, not to sell.

**Social proof / community.** Sankofa is about belonging, so lead with community,
not vanity metrics:
- If you have numbers: *"Join 12,000+ learners reclaiming Twi."*
- If you don't yet: *"Join a growing community learning in 40+ countries."* or
  *"Be part of the Sankofa movement."*
- Place one line directly under the hero CTA, plus a tiny trust row:
  *"7-day free trial · cancel anytime · managed by your app store."*

**Friction & defaults.** Annual pre-selected, trial framing removes risk ("free
for 7 days" beats "€59.99 now"), and "cancel anytime" kills the commitment
objection. One primary action per screen.

**Loss aversion (brand-aligned).** A subtle Sankofa line near Free —
*"Don't leave the language behind"* — nudges without guilt-tripping.

---

## Implementation notes (maps to existing code)
- Update `plan_picker_screen.dart` (post-signup) and `upgrade_screen.dart`
  (Profile → Upgrade) to this layout; reuse `CurrencyService.format()` for all
  prices and the charcoal/gold/terracotta tokens already in `theme.dart`.
- Keep `kBillingEnabled` gating: while false, CTAs read "Start free trial"
  but route to the "coming soon" state — copy above still applies.
- Legacy-only perks (founder price-lock, Legacy badge, early access) are new
  flags to add when billing goes live; safe to show as value props now.
