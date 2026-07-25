# UI/UX Design Review — Sankofa Twi (lesson flow & core UI)

Reviewed against the live build: `lesson_quiz_screen.dart`, `continue_button.dart`,
`theme.dart`, `app_shell.dart`, and the feature screens. Date: 30 June 2026.

**First, the strengths (keep these):** a disciplined design system — one accent
(terracotta) reserved strictly for CTAs, neutral grayscale structure, consistent
`FloatingCard`, haptics + sound on the primary button, answer states encoded by
**color *and* icon** (not color alone), and reduce-motion guardrails. That's a
strong, coherent foundation. The notes below are about focus and polish, not a
rebuild.

---

## 1. Visual hierarchy & weight

**Issue — the primary task is buried.** In `lesson_quiz_screen.dart` the screen is
one long `ListView`: title → Vocabulary Spotlight card → Glossary card → Grammar
card → *then* the "Challenges". A learner scrolls past three dense reference cards
before reaching the thing they came to do. The teaching content and the practice
task have equal visual weight.
- **Do:** Split **Learn** from **Practice**. Either (a) put the three reference
  cards behind a collapsed "Review the words" expander that's open by default only
  on first visit, or (b) make the lesson two steps — a Learn screen, then a
  "Start practice →" CTA into the questions.

**Issue — the primary CTA isn't where the eye/thumb expects.** `ContinueButton`
sits at the very bottom of the scroll, so on a long lesson it's off-screen until
you scroll all the way down. The most important action is the least reachable.
- **Do:** Pin Continue to a **sticky bottom action bar** (a `bottomNavigationBar`
  or a `Stack` with a bottom-aligned container + top hairline), always visible in
  the thumb zone. Show a thin **progress bar at the top** (questions answered /
  total) so position is obvious at a glance — the inline "3 / 10" counter is good
  but visually quiet.

**Good:** Within the vocab card the hierarchy is right — headword 24/w800, then
pronunciation and "sounds like" in slate at 13–14. Don't change that.

---

## 2. Layout & cognitive load

**Issue — the vocab card carries too much at once:** eyebrow label, headword,
speak button, IPA, "sounds like", gloss, Chale tip, "Key Twi sounds" chips, *and*
example sentences — all stacked in one card. That's 6–7 distinct information
blocks before the learner has done anything.
- **Do:** Phase it. Show headword + gloss + audio first; move "Key Twi sounds"
  and example sentences into a lightweight "More" reveal. Aim for ≤3 blocks
  visible on first paint.

**Issue — three competing ALL-CAPS eyebrows** ("VOCABULARY SPOTLIGHT", "BASIC
GRAMMAR", "WORDS & PRONUNCIATION") at 11px each. Per Refactoring UI, repeated
section labels at equal weight stop helping and become noise.
- **Do:** Keep one eyebrow per card at most, or drop them and let the bold
  heading carry the section. Sentence case reads softer than ALL-CAPS for
  learners.

**Spacing:** the 14px gaps between cards and `FloatingCard` padding are good.
Add a touch more breathing room (≥16px) between the last challenge and the
sticky CTA so the action doesn't crowd the content.

---

## 3. Navigation & flow

**Issue — top-level nav is a dropdown, not a bar.** `app_shell.dart` switches
sections via a `PopupMenuButton` ("Menu") over an `IndexedStack`. Interestingly,
`theme.dart` already defines a full `navigationBarTheme` — so the system is built
for a bar you're not using. A dropdown hides destinations behind a tap and is an
unusual pattern for a daily-use mobile app; discoverability and thumb-reach
suffer.
- **Do:** Replace it with a **Material 3 `NavigationBar`** (bottom) for 4–5 core
  destinations, e.g. **Learn** (Journey/Lessons), **Practice** (Quiz),
  **Discover** (Symbols/Lens), **Progress**, **Profile**. Move the long tail
  (Day Name, Translate, Leaderboard) into the relevant section or a "More" sheet.
- **Also reconsider the home tab:** the app lands on **Symbols** (`_index = 2`).
  Symbols are lovely but they're not the core learning loop — landing on
  **Journey/Lessons** puts "what do I do next" front-and-centre.

**Issue — a soft dead-end on a failed quiz.** When the score is below
`kPassScore`, tapping **Continue** only fires a snackbar ("Score X+ to unlock…").
A button styled as the primary action that refuses to act is confusing.
- **Do:** When the lesson is answered but failed, **swap** the CTA: make
  **"Try again"** the primary (filled) button and demote/hide Continue, so the
  next step is unambiguous. Today "Try again" is a quieter outlined button above
  a primary-looking Continue that does nothing.

---

## 4. Accessibility & clarity

**Issue (high priority) — primary CTA text fails contrast.** White text on
terracotta `#E2725B` is ≈ **3.1:1**. WCAG AA needs **4.5:1** for normal text;
the Continue label (16px, w600) is *not* "large text", so it fails. This is your
single most important fix because it's on the button you most want everyone to use.
- **Do:** Introduce a slightly deeper CTA fill (e.g. `#BE5235`–`#B84A2E`) that
  hits ≥4.5:1 with white while staying on-brand, and use it for
  `filledButtonTheme`. Keep the lighter terracotta for accents/illustration.
  (Your gold buttons already do this right — dark charcoal text on gold.)

**Issue — touch targets under 48dp.**
- Option tiles use `vertical: 13` padding → ~46dp tall. Bump to `vertical: 15–16`
  for ≥48dp.
- The `_SpeakButton` (especially the 18px example-sentence one) has an
  `InkResponse` radius of 22 around a small icon — the actual hit area is ~30dp.
  Wrap it to a **48×48 minimum** tap target (`SizedBox(width:48,height:48)` or
  `IconButton` with `constraints`). Pronunciation is a primary learning action —
  it should be easy to hit.

**Smallest type:** 11–11.5px labels (eyebrows, "Draft content" note) are at the
floor. Fine for non-essential captions, but don't put anything a learner *needs*
at <12px.

**Good:** correct/wrong states use icon + color + border, so they're not
color-only — that's exactly right for color-blind users.

---

## 5. Five actionable changes (Refactoring UI / M3)

1. **Sticky bottom action bar + top progress** on the lesson screen. Pin
   `ContinueButton`; add a 4px `LinearProgressIndicator` of answered/total at the
   top. (Hierarchy + reachability, biggest UX win.)
2. **Fix the CTA contrast.** Add a `terracottaDeep` (~`#BE5235`) for
   `filledButtonTheme` to clear WCAG AA 4.5:1. (One-line theme change, app-wide.)
3. **Adopt the Material 3 `NavigationBar`** you've already themed; demote the
   dropdown; default home to Journey/Lessons. (Discoverability + thumb-zone.)
4. **Enforce 48dp touch targets** on option tiles and all `_SpeakButton`s.
   (Accessibility, low effort.)
5. **Split Learn vs Practice / collapse reference cards** so the task isn't buried
   under three dense cards, and **swap the CTA to "Try again" on a failed quiz** to
   remove the dead-end. (Cognitive load + flow.)

> Quick-win order if you want the highest impact for least effort: **#2 (contrast)
> → #4 (touch targets) → #1 (sticky CTA + progress) → #3 (nav bar) → #5 (Learn/
> Practice split).** The first two are minutes; the rest are an afternoon each.
