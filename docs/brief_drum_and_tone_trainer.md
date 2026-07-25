# Development Brief — Drum & Tone Trainer

## Title
**Drum & Tone Trainer — "Twi is music"**

## One-Sentence
A rhythm-game layer that teaches Akan's make-or-break tonal pitch by having
learners tap, hum, and sing the high/low contour of words against a talking-drum
beat — scored live by their own voice.

## Full Description
Twi is a **tonal** language: the same string of letters means different things
depending on the pitch you say it at ("papa" → father / good / fan). This is the
single hardest thing for foreign learners and the thing every major competitor
quietly ignores, because it's hard to teach with multiple-choice cards. That gap
is the opportunity.

The Drum & Tone Trainer reframes tone as a music game — which is culturally exact,
because Akan talking drums (atumpan) literally *speak* by reproducing the tonal
contours of speech. The drum isn't decoration; it's the historically correct way
to represent the language's pitch.

Core loop:
1. **See it.** A word appears with its tonal contour shown as high/low dots over
   each syllable (the visual from the demo).
2. **Hear it.** Tap play: a talking-drum thump + a pitched tone per syllable plays
   the melody, so the learner internalises the shape as sound.
3. **Feel it.** A groove (looping drum bed) sets the tempo, turning practice into
   a rhythm game rather than a drill.
4. **Do it.** The learner reproduces the contour — first by tapping High/Low pads
   in time (v0), then by **humming or singing into the mic** (v1), where on-device
   pitch detection scores how closely their pitch contour matches the target.
5. **Land it.** Instant feedback, combo/streak multipliers, and a star rating;
   nailing a hard contour is a shareable "pow" moment.

It slots into the existing progression as its own skill track and as tonal
"boss rounds" inside regular lessons — and it feeds pedis/XP like everything else.

## The Magic Factor
**It teaches the one thing nobody else dares to, using the one mechanic that makes
it fun.** Tone is where learners plateau and where they sound foreign forever;
solving it with a talking-drum rhythm game is both a genuine pedagogical moat and
an irresistibly shareable format (think Guitar Hero meets language). It's hard to
copy — it needs real pitch-detection work *and* cultural authenticity — so it
doubles as a defensible differentiator and a viral hook ("can you sing this word
right?"). The drum makes a dry linguistics problem feel like play.

## Implementation Roadmap
**v0 — "Tap the contour" (proof of fun, ~2–3 weeks)**
- Hand-author ~10–15 words with verified tonal contours (consultant-checked).
- Build the demo into a real screen: dots visualisation, drum + pitched-tone
  playback (premium sound design), groove loop, High/Low tap pads, scoring,
  feedback, XP/pedis hookup.
- Ship as a single skill track to test whether the loop is *fun* before any audio
  ML. No mic yet.

**v1 — "Sing it" (the differentiator, ~4–6 weeks)**
- Add **microphone pitch detection** (real-time fundamental-frequency tracking)
  so learners hum/sing the contour and get scored on pitch shape, not just
  sequence. Prototype the pitch tracker on day one — this is the technical risk.
- Normalise for each user's vocal range (relative pitch, not absolute Hz).
- Combo multipliers, star ratings, "perfect tone" celebration animation/sfx.
- One polished talking-drum lesson pack with real atumpan samples.

**v2 — "Tone everywhere" (~ongoing)**
- Auto-generate tonal contours across the wider lexicon (data pipeline + review).
- Tonal boss rounds embedded in normal lessons; weekly "tone challenge" that's
  shareable to social.
- Leaderboard for tone accuracy; tie into the village/clan cohort idea.

## Resource Requirements
- **People:** 1 mobile engineer (Flutter, Web Audio/native audio), 1 audio/ML
  engineer for v1 pitch detection, a **sound designer** for drum + tone assets,
  and an **Akan language/music consultant** to verify every contour and supply
  authentic atumpan recordings (non-negotiable — wrong tones shipped to Ghanaian
  users would be embarrassing).
- **Tech:** native audio scheduling for low-latency playback; an on-device pitch-
  detection method (autocorrelation / YIN-style) — prefer on-device for latency
  and privacy (no voice leaves the phone); existing XP/pedis systems for rewards.
- **Assets:** recorded talking-drum hits and reference tones; a verified
  word→contour dataset (start small, expand).
- **Risks:** (1) pitch detection accuracy on noisy phone mics in real rooms —
  mitigate with relative-pitch scoring and forgiving thresholds; (2) latency
  making the rhythm feel off — budget < ~30ms audio latency; (3) tonal-data
  accuracy — gate on consultant review. **Validate the v1 pitch tracker as a
  throwaway prototype before building the full game.**
- **Timeline to a shippable v1:** ~6–9 weeks with the team above; v0 alone is a
  fast, low-risk win you can ship to gauge appetite.
