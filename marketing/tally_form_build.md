# Tally Form — Sankofa Twi Raffle (exact build sheet)

Recreate this in **Tally.so** (free, unlimited responses, has logic jumps). Build top to bottom; add a **Page break** where noted so logic can jump to the right ending. Paste the copy verbatim.

**Form settings**
- Title: `Win a heritage DNA kit 🧬 + test Sankofa Twi`
- Turn ON: "Email notifications to me" and "Connect → Google Sheets" (for the running count / first-50).

---

## PAGE 1 — the quiz

**Welcome text (Text block):**
> 🧬 Win a FREE heritage DNA kit + get early access to Sankofa Twi (learn Twi/Akan).
> 6 quick questions — 30 seconds. First 50 sign-ups are entered. Ends 31 July.

**Q1 — Multiple choice** (required)
Label: `Do you have African heritage?`
Options: `Yes` · `No` · `I'm not sure`

**Q2 — Multiple choice** (required)
Label: `Do you know exactly where in Africa your roots are?`
Options: `Yes, I know` · `I have an idea` · `No — I'd love to find out`

**Q3 — Multiple choice** (required)
Label: `Are you into African history & culture?`
Options: `Love it` · `A little` · `Not really`

**Q4 — Multiple choice** (required)  ← *disqualifier*
Label: `Would you like to learn an African language (like Twi)?`
Options: `Yes!` · `Maybe` · `No`

**Q5 — Multiple choice** (required)  ← *disqualifier*
Label: `What phone do you use?`
Options: `Android` · `iPhone (iOS)`

**Q6 — Multiple choice** (required)
Label: `Ready to test the app free and enter the raffle?`
Options: `Yes, count me in! 🎉`

**Sign-up fields (same page):**
- Short answer (required): `First name`
- Email (required): `Email` — description: "So we can enter you and send your tester invite."
- Short answer (optional): `Country`
- Checkbox (required): `I agree to the raffle terms & privacy policy` (link the terms page + sankofaapp.io/privacy)

*(End of Page 1 → default flows to the QUALIFIED thank-you page below, unless logic jumps fire.)*

---

## PAGE 2 — "Not for you" (soft DQ)
Add a **Page break**, then a Text block:
> No worries — thanks for stopping by! If you're curious about Ghana & Akan culture, follow **@sankofatwi** for a word a day. 🇬🇭

## PAGE 3 — iOS waitlist (hard DQ, captured)
Add a **Page break**, then:
Text block:
> Sankofa Twi is **Android-only** for now — the iPhone version is coming. Drop your email and you'll be first in line:
- Email (required): `Email for the iOS waitlist`
Text block (below): `Medaase! We'll email you the moment iOS is ready.`

## THANK-YOU PAGE — QUALIFIED (the payoff)
In Tally's **"Thank you" page** editor:
> You're in! 🎉 Install the app now — you're entered to win the DNA kit:
> 👉 **[ Get the app — Android ]**  ← button, URL = `https://appdistribution.firebase.dev/i/9586b57458a2b3d2`
> First 50 sign-ups qualify. Winner announced after 31 July. Medaase! 🇬🇭
- Add a secondary link: `Terms & conditions` → your terms page.

---

## LOGIC (Tally → "Logic" tab)
Add these two rules (they route people to the right ending):

1. **If** `Q4 (learn a language?)` **is** `No` **→ Jump to** `Page 2 — Not for you`.
2. **If** `Q5 (what phone?)` **is** `iPhone (iOS)` **→ Jump to** `Page 3 — iOS waitlist`.

Everyone else falls through to the **QUALIFIED thank-you page**. (Order matters: put the Q4 rule first.)

---

## After publishing
1. Copy the published form URL (e.g. `sankofatwi.tally.so/xxxx`).
2. Set it as your **Instagram bio link** (Edit Profile → Links) and use it on **Story Link stickers** and as your **paid-ad destination URL**.
   - Optional cleaner link: point `sankofaapp.io` (or a `/raffle` path) to redirect to the Tally URL, so "link in bio" reads on-brand.
3. Watch the connected Google Sheet; when you hit **50 rows** (Android + email), close entries. Add those emails as Firebase testers (or they've already self-installed via the button).
4. After 31 July: use a random-number pick on the row numbers to choose the winner; email them.

**Match-day tie-in:** tonight's Story graphics all say "link in bio" — that link is this Tally form. Post them, add the Link sticker to the form, and every match-day tap lands on the raffle.
