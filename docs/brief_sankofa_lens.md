# Development Brief — Sankofa Lens

## Title
**Sankofa Lens — "Point. Learn. Collect."**

## One-Sentence
Point your phone camera at anything in the real world — jollof, a trotro, your
shoe — and the app names it in Twi, drops it into your personal visual dictionary,
and rewards you for "first finds."

## Full Description
Most language apps trap learning inside the app. Sankofa Lens turns the entire
physical world into the lesson. The learner raises their camera at a real object;
the app recognises it, speaks and shows its Twi name (with the English gloss and
audio), and adds it to a growing **personal visual dictionary** — a shelf of
photos *they* took, each labelled in Twi.

Why it's sticky:
- **Endless, personal content.** The "deck" is the learner's own life — their
  kitchen, their street, their lunch. Vocabulary attaches to real memories, which
  is how words actually stick.
- **Collection mechanic.** Objects are "finds." First-time captures award bonus
  pedis/XP and badges ("first 50 objects", "kitchen complete", "market run").
  Gotta-catch-'em-all energy applied to a language.
- **Shareable moments.** A beautifully labelled photo of your jollof in Twi is a
  social object — organic marketing baked into the core loop.
- **Contextual culture.** Recognise a culturally specific object (kente, a
  talking drum, plantain) and Nana or a Chale-tip drops a one-line cultural note,
  linking Lens to the rest of the ecosystem.

It complements rather than replaces structured lessons: Lens is the "go outside
and use it" surface that makes the learner feel the language living in their world.

## The Magic Factor
**It makes the world your textbook — and your trophy case.** The instant a learner
points their camera at their own breakfast and hears it named in Twi, learning
stops feeling like homework and becomes a treasure hunt through their real life.
That emotional shift — from "studying a language" to "collecting my world in Twi"
— is something a flashcard app structurally cannot offer, and every labelled photo
a user shares is free, authentic, irresistible marketing.

## Implementation Roadmap
**v0 — "Name what I see" (proof of delight, ~3–4 weeks)**
- On-device image classification over a **curated set of ~200 common objects**
  (food, home, street, body, clothing) mapped to verified Twi words + audio.
- Camera screen: capture → label appears in Twi with gloss + TTS audio → save to a
  visual dictionary shelf.
- Deliberately scoped vocabulary (not open-world) so accuracy stays high and the
  experience feels magic, not flaky.

**v1 — "Collect the world" (the hook, ~4–6 weeks)**
- "First find" rewards: bonus pedis/XP, badges, set-completion ("kitchen", "market").
- Visual dictionary shelf with search, review (turn your finds into a quiz deck),
  and progress toward collections.
- Cultural-object notes (kente, drum, plantain) wired to Nana / Chale-tips.

**v2 — "Open world + social" (~ongoing)**
- Expand toward open-vocabulary recognition with a confidence threshold and a
  "not sure — is this X?" confirm step to keep trust high.
- Share-a-find: export the labelled photo as a branded card (ties to Adinkra Saga
  / shareable identity).
- Community "find of the week"; rare-object hunts tied to events/festivals.

## Resource Requirements
- **People:** 1 mobile engineer (Flutter + on-device vision/camera), a part-time
  ML engineer to select/tune the classifier and build the object→Twi mapping
  pipeline, an **Akan language consultant** to verify object names and record
  audio, and design for the camera UI + collection shelf.
- **Tech:** on-device image classification (prefer on-device for speed, offline
  use, and privacy — images shouldn't need to leave the phone for the curated
  set); existing TTS for object audio; Firestore/Storage for the user's visual
  dictionary; camera + permissions handling.
- **Data:** a curated, consultant-verified object→Twi-word dataset with audio
  (start ~200, expand). This dataset *is* the moat — invest here.
- **Risks:** (1) recognition accuracy/embarrassing mislabels — mitigate with a
  curated closed set + confidence threshold + "is this X?" confirm in v2;
  (2) privacy expectations around camera/images — keep recognition on-device where
  possible and disclose clearly in the Privacy Policy (update the AI/data sections);
  (3) cultural-naming accuracy — gate on consultant review.
- **Timeline to a shippable v1:** ~7–10 weeks with the team above; v0 with a tight
  200-object set is a strong, low-risk demo to validate the "treasure hunt" feel.
