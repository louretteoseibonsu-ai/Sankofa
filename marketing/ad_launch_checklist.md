# Ad Launch Checklist — "Learn Your Parents' Language" Test

*Follow top to bottom in Meta Ads Manager. Goal: lowest cost-per-tester, not likes.*

## Before you launch
- [ ] **Deploy the app-first funnel** (`git push`) so ad traffic lands on the new page. Confirm `sankofaapp.io/raffle` shows "Get the app free" as the primary button.
- [ ] Instagram is a **Professional/Business** account, linked to a Meta account.
- [ ] Creatives ready: `marketing/instagram/ads/AD_A_slipping_cream.png`, `AD_B_grandma_dark.png`, `AD_C_realflex_cream.png` (+ optional `AD_B_video` for a video ad set).

## Campaign setup
- [ ] **Objective:** Traffic → link clicks (NOT "Boost post" — boosting optimizes for engagement, not clicks).
- [ ] **Conversion location:** Website → `https://sankofaapp.io/raffle`
- [ ] One campaign, **three ad sets** (A, B, C) — same audience, one creative each. (Add a 4th ad set for the video if using it.)

## Budget
- [ ] **€5/day per ad set**, run **3–4 days** (~€45–60 total).
- [ ] Equal split so Meta shows you which hook wins cleanly. Don't let it auto-optimize budget across sets during the test (turn off Advantage campaign budget) — you want a fair read.

## Audience (same for all sets)
- [ ] **Geo:** US (Atlanta, DC/Maryland, New York), UK (London), Canada (Toronto). Ghanaian diaspora hubs.
- [ ] **Age:** 22–40
- [ ] **Interests:** Ghana, Accra, Afrobeats, jollof rice, Ghanaian food, "heritage", Ghanaian creators/musicians
- [ ] **Device / OS:** **Android only** (Detailed targeting or placement device filter) — stops spend on iPhone traffic that can't install.
- [ ] **Placements:** Manual → Instagram Feed, Explore, Reels. (Use the video creative for Reels placement.)

## Caption (identical across all sets — only the image changes)
> The language our parents speak shouldn't stop with us. 🇬🇭 Sankofa Twi teaches you to actually speak Twi — free, a few minutes a day, with real Ghanaian audio. Android beta open now 👇
>
> No purchase necessary. 18+. This promotion is not sponsored, endorsed or administered by Instagram/Meta. Terms: sankofaapp.io/raffle-terms

## After 3 days — read + decide
- [ ] Log spend / reach / link clicks / installs per hook in **tester_feedback_tracker.xlsx → Ad Test Log** (it auto-computes CTR + cost per tester).
- [ ] **Winner = lowest cost-per-tester** (installs), not most likes.
- [ ] Pause the two weakest ad sets. Put remaining budget behind the winner.
- [ ] Only scale the winner's budget *after* the funnel is converting (watch the tester group + `raffleEvents` collection fill up).

## Benchmarks (from your last run, for comparison)
- Last time: €27.16 → 1,883 reach, 55 visits (~2.9% CTR), **0 testers**.
- CTR was fine; conversion was the failure. If the app-first page works, the same traffic should now produce installs.
- Rough target: **under ~€5 per install** would be healthy for a beta at this stage.

## Compliance (already handled — keep it on)
- Instagram/Meta non-affiliation line: in the caption above ✓
- "No purchase necessary" + 18+: in caption and on the page ✓
- Full terms: `sankofaapp.io/raffle-terms` ✓
