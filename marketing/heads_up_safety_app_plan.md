# "Heads-Up" Walking-Safety App — Competitive Landscape, Plan & Roadmap

*Prepared 3 July 2026*

## The honest headline

The core idea — put a live rear-camera feed behind your phone screen so you can "see through" it while walking — **already exists and has for over a decade.** It's been built many times, is easy to clone, and most versions have been abandoned. On top of that, **Google baked a version of the safety nudge directly into Android for free.** So the naive product is not a business.

That doesn't kill the opportunity. It reframes it. The real, defensible product isn't a see-through screen — it's **active hazard detection**: an app that watches the path ahead and *warns you* about specific dangers (curbs, steps, roads, poles, people, cyclists) rather than just showing you a dim video. Nobody has nailed that as a clean, pure-software consumer app. That's the wedge this plan is built around.

---

## 1. Competitive landscape

### 1a. The "transparent screen" apps (the idea you described — already done)

This category is crowded and mostly dead:

- **Type n Walk** — one of the originals (2009–2010). Camera feed behind a text box so you can type and see the path. Novelty app, minimal traction.
- **Transparent Screen (Android)** — 2012, covered by TechCrunch and Android Police. Uses the camera to fake a see-through phone. Largely a novelty/prank category now (the Amazon Appstore even lists a "Transparent Screen launcher Prank").
- **Sidewalk Buddy (Android)** — a floating live video feed overlaid so you can "see through" your phone while texting. Closest to a real utility version, but low profile.
- **Iris (Nyomi Apps, Android)** — overlays a low-opacity live rear-camera feed on top of whatever app you're using, non-interactive so it doesn't block touches. Clever, but still passive.
- **Apple "transparent texting" patent (2014)** — Apple filed on the exact concept: modify an app's background to show a continuous rear-camera feed during messaging. They never shipped it as a feature, which tells you how much they valued it as a standalone thing.

**Takeaway:** the see-through-screen mechanic is commoditized, patented-around, and perceived as a gimmick. Ratings are mediocre, maintenance is poor, and it does not actually make walking-and-texting safe — it just adds a sliver of peripheral awareness. Building another one competes in a graveyard.

### 1b. The OS-level competitor (the real threat)

- **Google "Heads Up" (Digital Wellbeing, 2021→)** — built into Android. Detects (via the Physical Activity sensor) that you're walking while using your phone and pushes reminders like "Watch your step" / "Look up." It's free, pre-installed on Pixel and rolling out to more Android devices, and Google explicitly frames it as a *nudge* ("doesn't replace paying attention").

**Why this matters:** any generic "remind me to look up" app is already beaten by a free OS feature. But note what Heads Up does *not* do — it doesn't look at the world through the camera, and it can't tell you *what* the hazard is. It just knows you're walking. That gap is your opening.

### 1c. The research / hardware edge

- **Crash Alert** and various academic systems (e.g. SaferCross, texture-recognition papers on arXiv) use depth cameras or sensor fusion to detect obstacles and warn before impact. These prove the detection concept works but rely on special hardware or lab conditions. Modern phones now have the CPU/NPU and, on many models, LiDAR/depth to do a lot of this in pure software — which didn't exist when the transparent-screen apps launched.

### 1d. Market context (why anyone cares)

Distracted walking is a real, growing harm, which gives the product a genuine reason to exist and a PR/awareness angle:

- ~**$500M/year** in U.S. ER costs attributed to distracted walking.
- Distraction linked to **~2,500 pedestrian deaths (2021)** per National Safety Council figures cited in the coverage.
- Distracted walking raises fall likelihood **~70%**, and being hit by a vehicle **~2.4×** when crossing distracted.
- **40%+** of pedestrians use phones while walking; **~60% of teens** text-and-walk daily.

*(These are secondary-source figures for framing, not audited statistics — see "verify before pitching" note at the end.)*

**Bottom line on landscape:** the mechanic you described is a solved, low-value commodity, and Google owns the generic nudge. A viable business has to move up the stack to *intelligent hazard detection + a habit/behaviour layer*, where no one has shipped a clean consumer winner.

---

## 2. The wedge: what to actually build

**Positioning:** not "text through your screen" but **"a co-pilot for your eyes when you're on your phone."**

Three layers, in order of defensibility:

1. **Smart hazard detection (the core).** Real-time, on-device computer vision on the rear camera that classifies *specific* hazards — approaching curb/step-down, road/traffic edge, stationary obstacles (poles, bollards, walls), moving people/cyclists, stairs. When a real hazard is detected, escalate: subtle → haptic buzz → audio/visual alert. This is the thing Heads Up and the transparent-screen apps can't do.

2. **The see-through view (the familiar hook).** Keep an optional low-opacity live camera layer as the recognizable feature that gets people in the door and demos well — but it's the *supporting* feature, not the pitch.

3. **Behaviour & habit layer (the retention + moat).** "Safe streak" stats, weekly awareness reports, gentle goals to reduce phone-walking, family/child safety mode. This is what turns a one-tap gimmick into a retained, monetizable product and is hard to clone quickly.

**Sharpest initial target audience (pick one to start):**

- **Parents of tweens/teens** (highest willingness to pay for a "safety" product; teens are the heaviest text-walkers). A parent-controlled safety mode is a clean paid hook.
- Secondary: **low-vision / accessibility** users, where obstacle-detection has real utility and a values-driven story — but this is a regulated, high-stakes space, so treat as a later, careful expansion, not the launch wedge.

---

## 3. Product scope

**MVP (v0 — the smallest thing worth shipping):**

- One-tap "Safe Walk" mode: floating, low-opacity live camera layer over any app (overlay permission).
- On-device detection of 2–3 highest-value hazards only: **road/curb edge**, **large static obstacle**, **person directly ahead**.
- Escalating alert: haptic buzz + a red edge-flash when a hazard is close. No audio at MVP (privacy/annoyance).
- Auto-activate when "walking + screen on" is detected (reuse the same Physical Activity signal Heads Up uses), so it's zero-effort.
- Clear, prominent safety disclaimer + onboarding ("this assists, it does not replace looking up").

**Explicitly out of scope for MVP:** turn-by-turn, crossing/traffic-light detection, cloud processing, iOS (start Android — you already have the toolchain and it's the friendlier platform for overlays and background sensing).

**v1 adds:** hazard variety (stairs, cyclists, poles), the "safe streak"/awareness dashboard, parent mode, tuning per-user sensitivity.

---

## 4. Technical approach

You already have the stack for most of this (Flutter + Firebase + on-device ML from the Sankofa Lens work — you've shipped ML Kit image labeling before, so this is adjacent, not new territory).

- **App shell:** Flutter (reuse your existing toolchain, Firebase Auth/Firestore, App Distribution beta pipeline).
- **Camera + overlay:** Android foreground service + `SYSTEM_ALERT_WINDOW` (draw-over-other-apps) for the floating layer; `CameraX` feeding frames to the detector. This is the trickiest platform piece — overlay + camera-in-background has battery, permission, and OEM-quirk challenges. Prototype this *first* to de-risk.
- **Detection:**
  - Fastest path: **on-device object detection** (ML Kit Object Detection & Tracking, or a quantized YOLO-nano / MobileNet-SSD via TensorFlow Lite / MediaPipe) at a low frame rate (5–10 fps is plenty) to save battery.
  - "Is it close / approaching?" = object bounding-box growth over frames (looming detection) — cheap and effective without depth hardware. On LiDAR/ToF phones, optionally use depth for precision later.
  - Curb/road-edge detection is the hard CV problem; start with "large object rapidly filling lower frame" heuristics before investing in a trained segmentation model.
- **Movement/context:** Physical Activity Recognition API to auto-trigger only when walking; screen-on state to only run when needed.
- **Everything on-device.** No frames leave the phone — this is both a privacy selling point and a cost/latency necessity. Firestore only for accounts, settings, streak stats.
- **Battery is the #1 technical risk.** Budget real engineering time on duty-cycling the camera and model. An app that drains 20%/hour dies on the first review.

---

## 5. Monetization

- **Free tier:** basic see-through mode + haptic hazard buzz. Wide funnel, good for PR/virality.
- **Pro (subscription, ~€2.99–4.99/mo or ~€20/yr):** full hazard set, sensitivity tuning, awareness dashboard/streaks.
- **Family plan (the real revenue):** parent dashboard + child safety mode + "your kid walked distracted X times this week" report. Parents pay for safety; this is the highest-LTV segment.
- Avoid ads (a camera-overlay utility with ads reads as sketchy and hurts trust on a safety product).

Realistically this is a **modest-to-moderate revenue** consumer utility, not a venture-scale company, unless the family-safety angle or a B2B2C licensing deal (insurers, phone OEMs, school districts) takes off. Set expectations accordingly.

---

## 6. Go-to-market

- **Story-first, not feature-first.** The distracted-walking harm stats + a striking demo video (split screen: person about to trip vs. app buzzing them) is the whole marketing engine. This is inherently shareable and press-friendly — the original transparent-screen apps all got TechCrunch/Gizmodo coverage purely on novelty; you have novelty *plus* a real safety angle.
- **Short vertical video** (you're already building this muscle for Sankofa Twi) — the "watch it catch the curb" demo is a natural Reel/TikTok.
- **Beta via Firebase App Distribution** (same pipeline you already run) → then Play Store.
- **Angle for parents:** back-to-school timing, parenting creators/communities, safety-focused press.
- **PR hook:** "Google reminds you to look up. This app tells you what you're about to walk into."

---

## 7. Roadmap

**Phase 0 — De-risk (2–3 weeks).** Before committing: build a throwaway Android prototype that proves the hard part — a floating low-opacity camera overlay running over other apps, feeding frames to ML Kit Object Detection, buzzing when a bounding box looms large, all at acceptable battery. If this feels bad (battery, jank, OEM permission hell), stop or rethink here. **This phase decides whether the project is real.**

**Phase 1 — MVP build (4–6 weeks).** Auto-trigger on walking+screen-on; 2–3 hazard types; escalating haptic + edge-flash alert; onboarding + safety disclaimer; settings. Ship to a private beta (friends/family) via App Distribution.

**Phase 2 — Closed beta + tuning (3–4 weeks).** 30–100 testers. Instrument false-positive / missed-hazard rates and battery. Tune thresholds. This is where the product is won or lost — a jumpy or sleepy detector both fail.

**Phase 3 — Play Store soft launch (2–3 weeks).** Free tier only. Landing page + demo video. Gather reviews, ASO, watch retention.

**Phase 4 — Monetize (ongoing).** Add Pro + Family plans, awareness dashboard/streaks, parent mode. Push the parent-safety GTM.

**Phase 5 — Expand (later, optional).** More hazard types, LiDAR/depth on supported phones, crossing/traffic detection, careful accessibility/low-vision exploration (regulated — get expert input), possible iOS, and B2B licensing conversations.

**Rough total to a monetizing Play Store app: ~4–5 months of focused part-time work**, with Phase 0 as a hard go/no-go gate.

---

## 8. Key risks & honest caveats

- **Liability.** This is a *safety* product; if someone gets hurt trusting it, that's exposure. You must (a) market it as an *assistant that does not replace attention*, (b) put that in onboarding, ToS, and the store listing, and (c) never over-claim detection accuracy. Get the disclaimer language right (you already have the compliance instinct from the Sankofa raffle work).
- **You're arguably enabling the dangerous behaviour** you're claiming to fix — reviewers and press will raise this. The behaviour/habit layer ("we help you do it *less*") is your answer, and it should be genuine, not a fig leaf.
- **Battery / performance** can kill it on day one. Phase 0 exists for this reason.
- **Google could extend Heads Up** to include camera-based detection and end the category overnight. Move fast, and build the family/behaviour moat they're unlikely to copy.
- **It may simply be a small market.** People know text-and-walk is dumb; many won't install a tool for it. Validate demand cheaply (a landing page + demo video measuring sign-ups) *before* heavy build.
- **App Store review** for a persistent camera + draw-over-apps utility is stricter than average — expect scrutiny on the always-on camera permission.

---

## 9. Recommendation

Don't build another transparent-screen app — that idea is spent and Google owns the free nudge. **Do** build the *hazard-detection co-pilot* if — and only if — Phase 0 proves the overlay+detection+battery story on real Android hardware. Before writing much code, stand up a one-page site with the demo concept and measure whether people actually want it. If the signal's there and Phase 0 feels good, it's a legitimate, PR-friendly, modestly monetizable utility with a real family-safety upside. If Phase 0 feels bad, walk away cheaply — you'll have spent three weeks, not six months.

---

*Note: the market/injury figures in §1d come from secondary sources (advocacy sites, law-firm blogs, aggregators) and should be verified against primary sources — National Safety Council, CDC/NHTSA, peer-reviewed studies — before using any of them in a pitch deck, investor doc, or the app's marketing.*
