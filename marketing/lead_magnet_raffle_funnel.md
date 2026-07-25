# Sankofa Twi — Instagram Lead-Magnet Raffle Funnel

**Goal:** 50 sign-ups to test the Android app. **Incentive:** win a free heritage / ancestry DNA test kit. **Ends:** 31 July 2026.

---

## 0. First-ad read-out (what we learned)
- €10 → 13 clicks (~€0.77/click), 2 followers, from the Ghana vs Colombia creative.
- Best-engaged: **men, 24–54.** That's your beachhead audience — lean into the football/diaspora angle for the raffle push.
- To hit 50 completed sign-ups you need traffic × conversion. A raffle typically converts far better than a plain "join the beta," so expect a higher rate — but plan for ~100–170 clicks total (see §6).

---

## 1. Design principle — disqualify only when you must
You want logic jumps, but every hard "no" costs a tester. So:
- **Hard screen (must):** iPhone/iOS → can't install → send to an **iOS waitlist** (capture email, don't dead-end).
- **Soft screen:** "I don't want to learn a language" → not a fit → thank + follow CTA.
- **Everything else continues.** Heritage and history are *engagement* questions that personalise the raffle, not disqualifiers — a non-heritage person who loves African languages is still a great tester.

*(If you specifically want a diaspora-only list, you can add a hard screen on "African heritage → No", but it will shrink your pool. Recommendation: don't, for a 50-tester goal.)*

---

## 2. The funnel (question-by-question)

**Intro screen**
> 🧬 Win a FREE heritage DNA kit + get early access to Sankofa Twi.
> Answer 6 quick questions (30 seconds). First 50 sign-ups are entered to win.

**Q1 — Do you have African heritage?**  · Yes / No / I'm not sure
→ *all continue.* (Segment for messaging.)

**Q2 — Do you know exactly where in Africa your roots are?**  · Yes, I know / I have an idea / No — I'd love to find out
→ *all continue.* ("No" = strongest DNA-kit hook — show them extra love on the end screen.)

**Q3 — Are you into African history & culture?**  · Love it / A little / Not really
→ *all continue.*

**Q4 — Would you like to learn an African language (like Twi)?**  · Yes! / Maybe / No
→ **No = SOFT DISQUALIFY.** Jump to *Screen A* (thanks/follow).
→ Yes / Maybe → continue.

**Q5 — What phone do you use?**  · Android / iPhone (iOS)
→ **iPhone = HARD DISQUALIFY.** Jump to *Screen B* (iOS waitlist — capture email).
→ Android → continue.

**Q6 — Ready to test the app free and enter the raffle?**  · Yes, count me in! 🎉
→ Go to **Sign-up screen.**

**Sign-up screen (the conversion)**
- First name *(required)*
- Email *(required)* — "so we can enter you in the raffle and send your tester invite"
- Country *(optional)*
- ☐ I agree to the raffle terms & privacy policy *(required checkbox, links below)*

**End screen — QUALIFIED (the payoff)**
> You're in! 🎉 Install the app now and you're entered to win the DNA kit:
> 👉 **[Get the app — Android]** (your Firebase invite link / sankofaapp.io)
> First 50 sign-ups qualify. Winner announced after 31 July. Medaase! 🇬🇭

---

## 3. Disqualification / capture screens

**Screen A — soft DQ (doesn't want to learn a language)**
> No worries — thanks for stopping by! If you're curious about Ghana & Akan culture, follow @sankofatwi for a word a day. 🇬🇭

**Screen B — iOS waitlist (hard DQ, but captured)**
> Sankofa Twi is **Android-only** for now — iPhone version is coming. Drop your email and you'll be first in line (and still eligible for a future raffle):
> [ email field ] → "Join the iOS waitlist"

---

## 4. What you capture (per entry)
Name · Email · Phone OS · Heritage segment (Q1) · "knows roots?" (Q2) · language intent (Q4) · country. Export as CSV → add the first 50 Android emails as Firebase testers (or they self-install via the link) → email the winner.

---

## 5. Raffle terms (paste on a linked page; not legal advice — verify locally)
- **No purchase necessary.** Open to entrants **18+** in [list your regions].
- **How to enter:** complete the sign-up (Android app installed + email submitted) by **31 July 2026, 23:59 CET.**
- The **first 50** completed sign-ups are entered. One entry per person.
- **Prize:** one at-home heritage/ancestry DNA test kit (approx. value €[__]). Not exchangeable for cash.
- Winner drawn at random within 7 days of close, notified by email; must respond within 7 days or a new winner is drawn.
- Genetic testing involves sensitive personal data handled by the **kit provider** under *their* terms/privacy policy — Sankofa Twi only ships the kit.
- Your email is used only for the beta + this raffle, per the Sankofa Twi Privacy Policy (sankofaapp.io/privacy).
- **Instagram disclaimer (required):** "This promotion is in no way sponsored, endorsed, administered by, or associated with Instagram or Meta."
- **EU/Spain note:** free prize draws are generally outside gambling law, but publishing simple "bases legales" (these terms) is good practice — confirm if you're unsure.

---

## 6. Build it (recommended: Tally.so — free, unlimited responses, logic branching)
1. Create a new Tally form; add the 6 questions + sign-up fields above.
2. **Logic:** Q4 = No → jump to Screen A (end). Q5 = iPhone → jump to Screen B (end). Otherwise continue.
3. **Completion redirect / thank-you:** show the install link (and/or redirect to sankofaapp.io).
4. Turn on **email notifications** to yourself; connect to a Google Sheet for the running list.
5. Publish → copy the form link.
*(Typeform looks nicer but its free tier caps responses too low for 50 — use Tally.)*

**Wire it to Instagram**
- Put the form link in your **bio link** and in **Story Link stickers**.
- Point your **paid ad's destination URL** at the form (not the homepage) — the quiz + prize converts better.
- Announce it in a Story + pin a raffle post.

---

## 7. Plan to hit 50 sign-ups
**Paid (retarget your winners):**
- Build a **retargeting audience** from the people who engaged with the Ghana vs Colombia ad + any video viewers, and a **1% lookalike** once you have ~50 emails.
- Target the segment that's already biting: **men 24–54, Ghana + diaspora, football/afrobeats interests.**
- Budget math: at ~€0.77/click and a raffle-boosted ~30–40% completion, ~€75–130 gets you to ~50. Start €5–10/day, kill weak creatives after 3–4 days.

**Organic (free, do all of these):**
- Post the **Sankofa Lens Reel** + a dedicated **"Win a DNA kit" Reel/Story** with the Link sticker.
- Add urgency everywhere: **"first 50 only · ends 31 July."**
- Seed it in Ghana/diaspora groups, WhatsApp, and reply to comments with the link.

**Watch this metric:** cost (and count) per **completed sign-up**, not clicks or followers. A €10 test that yields 8 sign-ups beats one that yields 200 followers.

---

## 8. One creative-direction tip
Frame the prize as **"Find your roots, then speak the language."** The DNA kit (where you're from) + the app (how they speak) is a single, coherent story — and Q2's "No, I'd love to find out" people are your hottest leads. Put that line in the ad and the intro screen.
