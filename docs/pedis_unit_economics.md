# Pedis & Credits — Unit Economics (with real Khaya pricing)

## Khaya AI API tiers
| Tier | Price/mo | Calls/mo | Effective €/call¹ | TTS? |
| --- | --- | --- | --- | --- |
| Developer | Free | 100 | — | no |
| Basic | $14.95 | 3,000 | ~$0.0050 | no |
| Standard | $89.95 | 20,000 | ~$0.0045 | **yes** |
| Enterprise | $749 | 200,000 | ~$0.0037 | yes |

¹ effective rate only if you use the full quota; underuse makes each call cost
more. Khaya bills by **total API calls**, and the tiers are flat monthly buckets.

## Two facts that change the design
1. **You must be on Standard ($89.95/mo) to have TTS at all.** Translation +
   Lens alone could sit on Basic, but the moment you ship "Listen" / "Say it out
   loud" audio you need Standard minimum. Budget that fixed cost from day one.
2. **Every audio play is a billed Khaya call**, exactly like a translation. Today
   TTS is unmetered and unlimited — so a Translate action that also plays audio is
   **2 calls**, and replaying dictionary audio in Lens is +1 each. The "500
   included credits" can quietly generate 1,000–1,400 Khaya calls per heavy user.

## Test 1 — overage is very healthy ✅
Overage sells at 2 pedis/credit. Pedi value ≈ €0.0099 (entry pack) → ~€0.0198
≈ **$0.021 per credit** vs ~$0.0045 cost = **~4.7× markup**. Profitable in every
tier. No change needed.

## Test 2 — the subscription covers Khaya only above ~20 subs
Net per €4.99 sub ≈ $3.78 (30% store fee) to $4.59 (15%).
Standard tier ($89.95) break-even = **$89.95 ÷ $3.78 ≈ 24 premium subs** (or ~20
at a 15% fee) — just to cover the Khaya bill, before any margin. Fine as you grow;
just know the first ~two dozen subs pay for the API, not profit.

## Test 3 — the quota ceiling (the real constraint) ⚠️
Standard = 20,000 calls/month total, across ALL users.
- Today's allowance: 500 translate + 200 Lens = 700 metered calls/user, **plus
  unmetered audio** → a heavy user can hit ~1,000–1,400 Khaya calls/month.
- 20,000 ÷ ~1,200 ≈ **only ~16 heavy premium users** before you blow the Standard
  quota and must jump to Enterprise ($749). That's the binding limit, not revenue.

## Recommendation — switch to ONE unified AI-credit pool
The cleanest cost control is **1 credit = 1 Khaya call**, whatever the type
(translate, Lens scan, OR audio play). Then the included allowance *is* a hard cap
on Khaya calls per user, and the quota math becomes exact.

Proposed defaults:
- **Premium: 400 AI credits / month** (covers translate + scan + audio combined).
  → 20,000 ÷ 400 = **up to 50 premium users on Standard** before Enterprise.
- **Free: 15 credits / month** taster.
- **Overage: keep 2 pedis / credit** (~4.7× markup).
- **Meter audio**: each "Listen" / "Say it out loud" spends 1 credit too.

If you'd rather not charge for audio, the alternative is a separate small audio
allowance (e.g. 150 plays/mo) so it's still capped — but unified is simpler and
safest.

## Concrete next steps I can implement
1. Collapse the separate translate/Lens buckets into one **AI credits** pool
   (the `CreditsService` already supports this — one config, shared counter).
2. Make TTS calls consume a credit (Translate "Listen", Lens "Say it out loud",
   and dictionary replays).
3. Set Premium 400 / Free 15, overage unchanged.
4. Update the plan copy from "300 + 200" to "400 AI credits/month."

Net effect: predictable Khaya cost (≤400 calls/user), ~4.7× overage margin, and a
clear signal (active premium count) for when to move Standard → Enterprise.

---

## Profitability with the $89.95 Standard tier priced in (UPDATED)

We now have three cost controls live, so the **Khaya cost per active user is
small**:
1. **Bundled lesson audio** — lesson pronunciation plays from files in the app =
   **0 Khaya calls** (this was the biggest drain).
2. **Audio caching** — repeat plays in a session don't re-call the API.
3. **400-credit/month cap** per premium user across Translate + Lens + arbitrary
   audio.

So the real cost is mostly the **fixed $89.95/month Standard tier** (≈ €82),
which alone covers up to ~20,000 calls/month — plenty for a small user base once
lesson audio is free.

**New pricing (priced to cover the fixed cost with margin):**
- Premium **€6.99/month** or **€59.99/year** (≈ €5.00/mo, "save ~28%").

**Break-even on the $89.95 (≈€82) Khaya tier:**
| Store fee | Net per monthly sub | Subs to cover €82 |
| --- | --- | --- |
| 30% | ~€4.89 | **~17 subscribers** |
| 15% (small-business) | ~€5.94 | **~14 subscribers** |

So **~15 paying subscribers covers your entire Khaya bill**; every subscriber
beyond that is mostly margin (minus minor Render/Firebase costs). An annual
subscriber pays ~€42–51 net for the year while costing at most ~€20 of Khaya
calls (400/mo × 12 at the Standard rate) — comfortably profitable.

**Bottom line:** with bundled audio + caching + the credit cap, the app is
profitable once you pass ~15 subscribers, and the €6.99 / €59.99 price builds in
real margin on top of the fixed Khaya cost. Lower the price later if you want
more growth and less margin — it's two constants in `upgrade_screen.dart` /
`plan_picker_screen.dart`.
