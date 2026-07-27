/// Backend base URL for translation + Twi audio.
///
/// IMPORTANT: set this to YOUR deployed Render URL (the one you open in a browser),
/// e.g. 'https://sankofa-twi.onrender.com'. The app calls <base>/api/translate and
/// <base>/api/tts so the Khaya/Gemini keys stay on the server, never in the app.
const String kBackendBaseUrl = 'https://sankofa-twi.onrender.com';

/// Master switch for motion / celebratory animations. Turn off to ship a
/// fully static build. Animations ALSO auto-disable when the OS "reduce
/// motion" accessibility setting is on (see widgets/animations.dart).
const bool kAnimationsEnabled = true;

/// Master switch for paid features (premium Ananse avatar, etc.).
/// Keep this FALSE until real billing is wired up (in_app_purchase + a
/// verified payment gateway). While false, the premium unlock is shown as
/// "coming soon" and never grants premium.
const bool kBillingEnabled = false;

/// Testing-launch override: the new premium features (Sankofa Lens, and later
/// the Nana Line + Drum & Tone Trainer) are marketed as Premium but unlocked
/// for everyone during the test launch so users can try them. Flip to FALSE
/// once billing is live to enforce the paywall.
const bool kLensFreeDuringTesting = false;

// ── Unified AI credits (Khaya calls) ────────────────────────────────────────
// AI Translate, Sankofa Lens scans, AND audio (TTS) all draw from ONE monthly
// pool: 1 credit = 1 Khaya API call. This caps per-user backend cost directly
// (Khaya bills by total calls). When the allowance runs out, users top up with
// pedis (soft currency), up to a monthly purchase cap.
/// Included AI credits per month for Free users (a taster).
const int kFreeMonthlyAiCredits = 15;

/// Included AI credits per month for Premium / Legacy subscribers.
/// Sized so 20,000 Khaya Standard-tier calls support ~50 maxed premium users.
const int kPremiumMonthlyAiCredits = 400;

/// Overage: extra credits per pedi-purchase, and its price.
const int kAiCreditPackSize = 10;
const int kAiCreditPackPedis = 20;

/// Cap on extra credits bought with pedis per month (protects backend cost).
const int kAiMaxMonthlyExtra = 400;

/// Referral reward: pedis granted to BOTH the inviter and the new friend when a
/// friend redeems an invite code. Keep in sync with REWARD in functions/index.js.
const int kInviteRewardPedis = 100;

/// Sankofa Lens — minimum ML Kit confidence (0..1) for a label to be shown.
/// ML Kit's bundled on-device labeler only covers ~400 generic categories, so
/// it has no real notion of "unsure": everything above this bar is shown as a
/// candidate, everything below is silently dropped. 0.4 previously let too
/// many low-confidence, unrelated guesses through (e.g. "room"/"shoe"/"chair"
/// for a fan); 0.6 trades a bit of recall for results you can trust. If you
/// still see wrong labels at 0.6, the fix is a broader/custom model, not a
/// lower threshold — see docs/brief_sankofa_lens.md.
const double kLensConfidenceThreshold = 0.6;
