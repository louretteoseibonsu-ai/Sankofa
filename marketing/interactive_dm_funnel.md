# Interactive IG Lead Funnel — Comment-to-DM (not a boring form)

The engaging version of your raffle funnel lives **inside Instagram DMs** as a tappable chatbot conversation, triggered by a comment. Built with **ManyChat** (free plan works). It feels like chatting, branches on answers, captures the email, and hands over the install link — and the flood of comments boosts the post's reach.

## Why this beats a questionnaire
- **Native:** happens in the DM, not a web form — zero friction, no tab-switch.
- **Interactive:** tap buttons, get instant replies, GIFs, branching. Feels like a person.
- **Reach hack:** every "comment ROOTS" is a comment → the algorithm pushes the post harder.
- **Qualifies + captures** in the same flow (phone check, intent, email, link).

---

## The 3 layers

### 1) The trigger post/Reel
Use your match-day Reel or a raffle Reel. Caption ends with a keyword call:
> 🇬🇭 Win a heritage DNA kit + learn Twi free. Comment **ROOTS** and I'll slide into your DMs 👀 (Android · first 50 · ends 31 July)

### 2) Story warm-up (optional, drives comments/DMs)
A quick sticker sequence before/after posting:
- Poll: "Ghana tonight? Yɛbɛdi nkonim / Nervous 😅"
- Quiz: "How do you say Welcome in Twi? Akwaaba ✓ / Medaase"
- Question sticker: "Where are your roots? 👀"
- Final slide: "Want the DNA kit? Comment ROOTS on my last post" (or a Link sticker to the form as fallback).

### 3) The DM chatbot flow (the star) — ManyChat
Trigger: someone comments **ROOTS** → auto-DM opens this conversation. Buttons in [brackets].

**Msg 1 — open**
> Akwaaba! 🇬🇭 You said ROOTS — let's find yours *and* get you in for the DNA kit. Ready?
[ Let's go → ]

**Msg 2 — phone check (disqualifier)**
> Quick one: what phone do you have?
[ 🤖 Android ]   [ 🍏 iPhone ]
- **iPhone →** "Ah! Sankofa Twi is Android-only right now — iOS is coming. Want to be first in line?" [ Yes, add me ] → *collect email* → "Medaase! You're on the iOS waitlist. 🇬🇭" **(end, captured)**
- **Android →** continue.

**Msg 3 — intent (disqualifier)**
> Real talk — do you actually want to learn Twi, not just vibes? 😄
[ Yes! 🔥 ]   [ Maybe ]   [ Not really ]
- **Not really →** "All good! Follow for a word a day 🇬🇭" **(end, soft)**
- **Yes / Maybe →** continue.

**Msg 4 — roots (engagement + segment)**
> Do you know where in Africa your roots are?
[ Yes, I know ]   [ I'd love to find out ]
- **I'd love to find out →** "Then this DNA kit has your name on it 👀"
- **Yes, I know →** "Perfect — let's get you speaking the language of home."

**Msg 5 — capture**
> Last step: drop your email and you're entered in the raffle + I'll send your free tester invite. ✍🏾
(*ManyChat "Collect Email" step — validates format*)

**Msg 6 — deliver + CTA**
> You're IN! 🎉 Install the app here 👇 you're entered to win the DNA kit.
[ 📲 Get the app (Android) ]  → URL: https://appdistribution.firebase.dev/i/9586b57458a2b3d2
> First 50 sign-ups qualify. Winner announced after 31 July. Yɛbɛdi nkonim! 🇬🇭

---

## Build it in ManyChat (setup)
1. Make sure Instagram is a **Professional/Business** account.
2. Create a free **ManyChat** account → **connect your Instagram**.
3. New Automation → **Instagram → Comments**: trigger = keyword **ROOTS** on your chosen post → action: **Send DM** (start the flow).
4. Build Msgs 1–6 as a flow using **Buttons/Quick Replies** for the choices and **Condition/branch** steps for the logic (phone, intent).
5. Add a **Collect Email** step (saves to the contact's email field, with validation).
6. Add the **URL button** with your install link on Msg 6.
7. **Export the list:** ManyChat → connect to Google Sheets (or Zapier) so qualified emails land in a sheet → that's your first-50 raffle list + Firebase tester emails.
8. Turn on a **"keyword also works in DMs"** version so people who just DM "ROOTS" also enter.

**Compliance:** ManyChat operates within Meta's messaging rules (comment-triggered DMs + the 24-hour window are allowed). Keep the Instagram disclaimer ("not sponsored by Instagram") and raffle terms on a linked page.

---

## If you'd rather not use a chatbot
Next-best "interactive" options (still better than a plain form):
- **Typeform** — one-question-at-a-time, conversational feel, logic jumps (free tier caps responses, so use for a short run).
- **Tally** — the form build you already have; less flashy but free + unlimited.
- **Story-sticker-only funnel** — run the whole thing as polls/quizzes/question stickers, then a Link sticker. Fully native, but you can't branch/qualify as cleanly.

**Recommendation:** ManyChat comment-to-DM for the interactive, high-reach version; keep the Tally form as the "link in bio" fallback for people who prefer a page.
