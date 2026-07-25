# Development Brief — The Nana Line

## Title
**The Nana Line — "Wisdom on demand"**

## One-Sentence
An AI elder ("Nana") you talk to in imperfect Twi who replies in warm spoken
Akan — with a proverb, a gentle correction, and the patience of the grandparent
every learner wishes they had.

## Full Description
The Nana Line turns Sankofa Twi's existing translate/TTS pipeline (GhanaNLP /
Khaya) from a *tool* into a *relationship*. Instead of typing into a dictionary,
the learner opens a conversation with Nana — a persistent character with a voice,
a personality, and a memory.

The core loop:
1. The learner sends a message — typed or spoken — in any mix of Twi and English
   ("Nana, how do I say I'm tired?", or a shaky attempt: "Me… firi… work?").
2. Nana replies in **voice-first** Akan: a warm acknowledgement, the correct
   phrasing, a one-line gentle correction ("close, fie nua — we say…"), and often
   a short proverb (ɛbɛ) that fits the moment.
3. The reply is also shown as text with a tap-to-reveal English gloss, so the
   learner stretches to understand before leaning on translation.
4. Nana remembers the learner's weak spots and recurring mistakes, and threads
   them back in later ("you forgot the tone on 'papa' again, mehu wo").

Nana is not a chatbot dressed in kente. The personality is the product: unhurried,
encouraging, never sarcastic, occasionally telling a one-paragraph Anansesɛm when
the learner is discouraged. She code-switches to match the learner's level —
mostly English for a beginner, drifting into more Twi as they grow, which doubles
as an invisible difficulty curve.

Monetization fit: a few free Nana exchanges per day for Free users; unlimited +
voice-in + memory for Premium. Nana becomes a daily reason to open the app that
has nothing to do with streak guilt.

## The Magic Factor
**People don't come back to dictionaries — they come back to people.** A learner
will abandon a flashcard deck without guilt, but they won't want to disappoint
Nana, and they'll *miss* her. The emotional pull of a patient elder is something
no competitor's "AI tutor" captures, because everyone else builds a feature; we're
building a character rooted in a real cultural relationship (the Akan reverence
for elders). It's warmth as retention — and it's almost impossible to clone
without the cultural authenticity Sankofa already has.

## Implementation Roadmap
**v0 — "Nana can talk" (proof of feel, ~2–3 weeks)**
- Text-in → voice-out. A persona/system-prompt layer wrapping the LLM, tuned for
  Nana's voice: warm, corrective, proverb-aware, code-switching by level.
- Pipe replies through Khaya TTS for spoken Akan; render text + tap-to-reveal
  gloss.
- One screen, no memory yet. Goal: does a 3-message exchange *feel* like Nana?

**v1 — "Nana listens & remembers" (~4–6 weeks)**
- Voice-in via ASR so learners can speak their attempts.
- Per-user memory: store recurring errors and topics in the user doc; feed a
  compact summary back into the prompt so Nana references past mistakes.
- Free vs Premium gating (daily free exchanges; unlimited + voice-in for Premium).
- Safety + content guardrails; "Nana stays in character" constraints.

**v2 — "Nana reaches out" (~ongoing)**
- Proactive nudges tied to learning gaps ("you haven't practised greetings, bra")
  delivered as a notification in Nana's voice.
- Seasonal/cultural moments (Akan calendar, festivals) woven into her dialogue.
- Optional: Nana narrates the Anansesɛm that unlock premium avatars, linking this
  feature to the Adinkra Saga.

## Resource Requirements
- **People:** 1 mobile engineer (Flutter), 1 backend engineer (prompt + memory +
  ASR/TTS orchestration on the existing Render service), part-time Akan language
  consultant (voice, proverbs, correction quality — non-negotiable for
  authenticity), product/design for the conversation UI.
- **Tech / services:** existing GhanaNLP/Khaya TTS; an LLM for dialogue + the
  persona layer; an ASR provider for voice-in (v1); Firestore for memory; push
  notifications (v2).
- **Cost watch-items:** per-message LLM + TTS cost (cache proverbs/common replies;
  rate-limit Free tier); ASR minutes; latency budget for voice-out (target < ~3s
  to first audio so it feels conversational).
- **Risks:** correction accuracy (mitigate with consultant-reviewed evaluation
  set); staying in character; tone/dialect authenticity; voice quality of TTS.
  Validate "the feel" in v0 with ~10 real learners before building memory/voice-in.
- **Timeline to a shippable v1:** ~6–9 weeks with the team above.
