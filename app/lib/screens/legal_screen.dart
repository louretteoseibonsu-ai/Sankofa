import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

/// Simple in-app reader for the Privacy Policy / Terms.
class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),

      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(body,
                style: const TextStyle(height: 1.55, color: kVelvetInk, fontSize: 14)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }
}

/// Version string for the currently published legal text. Bump this whenever
/// the Privacy Policy / Terms change so recorded consents stay auditable.
const String kLegalVersion = '2026-06-30';

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTANT: These are detailed, compliance-aware TEMPLATES for an EU/Spain
// launch (GDPR — Regulation (EU) 2016/679 — and the Spanish LOPDGDD — Organic
// Law 3/2018). They are NOT legal advice. Fill in every [BRACKETED] placeholder
// and have a Spanish-qualified lawyer review and adapt them before publishing
// to the app stores. Update the "Last updated" date whenever you change them.
// ─────────────────────────────────────────────────────────────────────────────

const String kPrivacyPolicy = '''
Sankofa Twi — Privacy Policy
Last updated: 30 June 2026

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY AT A GLANCE
This plain-language summary helps you understand the essentials. The full
policy below is the legally binding version.

• Who we are: Lourette Osei Bonsu, based in Spain, is the "data controller"
  responsible for your data.
• What we collect: your email and display name, your learning progress, optional
  profile details (date of birth, gender), the text you send to our AI tools,
  and approximate location (from your IP) only to show local prices.
• Why we use it: to give you an account, run lessons and leaderboards, process
  subscriptions, and translate or voice text you ask us to (using AI).
• AI processing: text you enter into translation/audio features is sent to our
  AI provider (GhanaNLP / "Khaya") to produce the result. We do not use it to
  make automated decisions that have legal or similarly significant effects on
  you.
• Your rights: you can access, correct, delete, export, restrict, or object to
  the processing of your data, and withdraw consent at any time — from the app
  or by emailing us. You can also complain to the Spanish authority (AEPD).
• Keeping it safe: data is encrypted in transit, access is restricted, and we
  keep it only as long as needed.
• Contact: sankofa@aparato.ai (privacy) and sankofa@aparato.ai (support).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DATA CONTROLLER
The data controller responsible for processing your personal data is:
• Legal name: Lourette Osei Bonsu
• Trading name: Sankofa Twi
• Registered address: Carrer de Maignon 34, 08024 Barcelona, Spain
• Tax ID (NIE): Y0153486K
• Email (privacy): sankofa@aparato.ai
• Data Protection Officer (if appointed): Not appointed

If you are in the EU/EEA and have questions about how we handle your data, you
can contact us using the details above.

2. WHAT PERSONAL DATA WE COLLECT
(a) Information you give us
• Account data: email address and display name; and, if you sign in with
  Google, the basic profile information Google shares with us.
• Optional profile data: date of birth and gender (you choose whether to add
  these).
• Content you submit: text you type into the AI Translate / Twi audio features,
  and any messages or content you share through social features (e.g. pen-pals,
  if enabled).

(b) Information created as you use the app
• Learning data: lesson scores, XP, levels, streaks, daily activity, wisdom
  keys, "pedis" balance, badges, and premium status.
• Leaderboard data: your display name and XP, shown to other users in public
  rankings.

(c) Information collected automatically
• Approximate location: derived from your IP address solely to display prices in
  your local currency. We do not store your IP address for this purpose.
• Technical and diagnostic data: basic device and app information needed to
  operate the service and fix problems.

We do not intentionally collect "special category" data (e.g. health, religion,
political opinions). Please do not enter such data into free-text or AI fields.

3. LAWFUL BASES FOR PROCESSING (Article 6 GDPR)
We rely on the following legal bases:

• Performance of a contract (Art. 6(1)(b)): to create and run your account,
  deliver lessons and progress tracking, operate leaderboards that are core to
  the service, and process subscriptions and in-app purchases.
• Consent (Art. 6(1)(a)): for optional features and data — for example optional
  profile fields (date of birth, gender), optional social/pen-pal features, and
  any non-essential analytics or marketing. You may withdraw consent at any time
  without affecting prior processing.
• Legitimate interests (Art. 6(1)(f)): to keep the service secure, prevent
  abuse and fraud, and improve and debug the app. Where we rely on this basis we
  balance our interests against your rights, and you may object (see Section 8).
• Legal obligation (Art. 6(1)(c)): to comply with tax, accounting, and consumer-
  protection laws (e.g. retaining billing records).

4. USE OF ARTIFICIAL INTELLIGENCE (AI TRANSPARENCY)
Some features use AI to process the text you choose to submit:
• Provider: GhanaNLP / "Khaya" AI API (translation and text-to-speech).
• What is sent: the specific text you enter into the AI Translate or audio
  features. We do not send your AI inputs together with your identity beyond what
  is technically necessary to return the result.
• Purpose: to translate between languages and to generate spoken Twi audio
  (including phonetic and pronunciation modelling).
• How it works: outputs are generated automatically by language models. AI can
  make mistakes; results are provided for learning and should not be relied upon
  as professionally accurate translation.
• No solely-automated decisions with legal effect: we do not use AI to make
  decisions that produce legal effects concerning you or similarly significantly
  affect you (Art. 22 GDPR).
• In line with EU AI Act transparency expectations, we tell you when you are
  interacting with AI-generated output.

You can use most of the app without using the AI features. If you do not submit
text to the AI tools, no text is sent to the AI provider.

5. WHO WE SHARE DATA WITH (PROCESSORS & THIRD PARTIES)
We share data only as needed to run the service, under appropriate agreements:
• Google Firebase (Google Ireland Ltd.) — authentication, database, and storage
  hosting for your account and progress.
• GhanaNLP / Khaya — receives the text you choose to translate or voice.
• ipapi.co — estimates your approximate country from your IP for local pricing.
• Apple App Store / Google Play — process payments and manage subscriptions.

We do not sell your personal data.

International transfers: some providers may process data outside the EEA. Where
this happens, we rely on appropriate safeguards such as the European Commission's
adequacy decisions or Standard Contractual Clauses (SCCs). You can request a copy
of the relevant safeguards using the contact details above.

6. DATA RETENTION
• We keep account and learning data for as long as your account is active.
• If you delete your account, we delete or irreversibly anonymise your personal
  data without undue delay, except where we must retain certain records to meet
  legal obligations (e.g. billing/tax records, typically retained for the period
  required by Spanish law).
• Backups are cycled out on a rolling basis.
• AI inputs are processed to return your result and are not retained by us to
  build a profile of you.

7. SECURITY MEASURES
We implement appropriate technical and organisational measures, including:
• Encryption of data in transit (TLS/HTTPS) and authentication handled by
  Firebase Authentication.
• Access controls so that only authorised team members can access user records,
  enforced by database security rules.
• API security for our backend and AI calls.
• Restricted administrative tooling with role-based access.
No system is perfectly secure, but we work to protect your data and will notify
you and the competent authority of a personal data breach where legally required.

8. YOUR RIGHTS (Articles 15–22 GDPR; LOPDGDD)
You have the right to:
• Access — obtain confirmation of, and a copy of, the data we hold about you.
• Rectification — correct inaccurate or incomplete data.
• Erasure ("right to be forgotten") — have your data deleted.
• Restriction — limit how we process your data in certain cases.
• Portability — receive your data in a structured, commonly used, machine-
  readable format, and have it transferred where technically feasible.
• Objection — object to processing based on legitimate interests, and to
  direct marketing at any time.
• Withdraw consent — at any time, where processing is based on consent.
• Not be subject to solely automated decisions producing legal/similar effects.

How to exercise them: use the in-app controls (Profile → edit your data; Profile
→ Delete account) or email sankofa@aparato.ai. We respond within one month, as
required by the GDPR. We may need to verify your identity first.

Right to complain: if you believe we have mishandled your data, you may lodge a
complaint with the Spanish Data Protection Agency (Agencia Española de Protección
de Datos, AEPD), C/ Jorge Juan 6, 28001 Madrid — www.aepd.es — or your local EU
supervisory authority.

9. CHILDREN
Sankofa Twi is not directed to children under 14 (the minimum digital-consent age
in Spain under the LOPDGDD). We do not knowingly collect data from children under
14. If you believe a child has provided us data, contact sankofa@aparato.ai
and we will delete it.

10. COOKIES AND SIMILAR TECHNOLOGIES
The mobile app uses local device storage and identifiers only as needed to run
the service (e.g. keeping you signed in, remembering settings). We do not use
advertising cookies in the app.

11. CHANGES TO THIS POLICY
We may update this policy from time to time. We will change the "Last updated"
date above and, for significant changes, provide a more prominent notice in the
app.

12. CONTACT
• Privacy / data protection: sankofa@aparato.ai
• General support: sankofa@aparato.ai
• Postal: Carrer de Maignon 34, 08024 Barcelona, Spain
''';

const String kTermsAndConditions = '''
Sankofa Twi — Terms & Conditions
Last updated: 30 June 2026

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY AT A GLANCE
This summary is for convenience; the full terms below are binding.

• Who we are: Lourette Osei Bonsu, based in Spain, provides the Sankofa Twi app.
• Your licence: we grant you a personal, limited, non-exclusive, revocable
  licence to use the app — you don't own it.
• Play fair: no spam, no harassment of other users or pen-pals, no cheating,
  and no reverse-engineering or copying the app.
• Subscriptions: Premium is monthly or annual with a 7-day free trial; manage and
  cancel through your app store. EU consumers keep their statutory rights.
• AI is a study aid: AI translations and audio can be wrong — don't rely on them
  for important or professional use.
• Liability: we provide the app "as is" and limit our liability as far as the law
  allows, without removing your mandatory consumer rights.
• Law & courts: Spanish law governs; disputes go to the courts of Barcelona,
  subject to mandatory consumer-protection rules.
• Contact: sankofa@aparato.ai.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ABOUT THESE TERMS
These Terms & Conditions form a binding agreement between you and
Lourette Osei Bonsu, NIE Y0153486K, with registered address at
Carrer de Maignon 34, 08024 Barcelona, Spain ("we", "us", "Sankofa Twi"). By creating an
account or using the app, you agree to these terms and to our Privacy Policy.

2. ELIGIBILITY
You must be at least 14 years old (the minimum digital-consent age in Spain) to
use the app. If you are under the age of majority, you confirm you have your
parent's or guardian's permission. You must provide accurate registration
information.

3. LICENCE TO USE
We grant you a personal, limited, non-exclusive, non-transferable, revocable
licence to download and use the app on devices you own or control, solely for
your own non-commercial language learning. This licence does not transfer any
ownership; all rights not expressly granted are reserved.

4. YOUR ACCOUNT
You are responsible for your account and for keeping your login credentials
secure. Tell us promptly at sankofa@aparato.ai if you suspect unauthorised use.
You are responsible for activity that occurs under your account.

5. SUBSCRIPTIONS, FREE TRIAL & BILLING
• Premium is offered as a monthly or annual subscription, with a 7-day free
  trial for new subscribers.
• Prices are shown in your region's currency; you are charged in your app-store
  currency. Subscriptions renew automatically until cancelled.
• Manage or cancel anytime in your Apple App Store or Google Play account
  settings. Access continues until the end of the paid period. Trials cancelled
  before they end are not charged.
• Refunds are handled by the relevant app store under its policies.
• Right of withdrawal: digital content/services begin immediately with your
  consent; where required by EU consumer law you keep any applicable statutory
  withdrawal rights. The free trial means you can evaluate the service before
  being charged.

6. VIRTUAL ITEMS ("PEDIS"), KEYS & COSMETICS
In-app currency and items have no real-world monetary value, are non-transferable
and non-refundable, and may change or expire. They are a limited licence to use
within the app, not your property, and cannot be exchanged for cash.

7. ACCEPTABLE USE & PROHIBITED CONDUCT
You agree NOT to:
• send spam, advertising, or unsolicited messages through any social or pen-pal
  feature;
• harass, bully, threaten, impersonate, or send abusive, hateful, or sexually
  explicit content to other users or pen-pals;
• collect or misuse other users' personal data;
• cheat, manipulate leaderboards, use bots, or exploit bugs;
• reverse-engineer, decompile, disassemble, scrape, or attempt to extract the
  app's source code, content datasets, or models, except where such restriction
  is prohibited by law;
• copy, resell, sublicense, or commercially exploit the app or its content; or
• disrupt, overload, or attempt to gain unauthorised access to the service.
We may remove content and suspend or terminate accounts that breach these rules.

8. USER CONTENT & SOCIAL FEATURES
If the app lets you submit content or interact with pen-pals, you remain
responsible for what you share and you grant us a limited licence to host and
display it as needed to operate the feature. We may moderate, remove, or restrict
content and report unlawful content where required. Treat other learners with
respect.

9. AI FEATURES & EDUCATIONAL OUTPUT DISCLAIMER
The app uses AI (GhanaNLP / Khaya) to translate text and generate Twi audio.
AI-generated output is provided for learning purposes only, is produced
automatically, and may be inaccurate, incomplete, or inappropriate for a given
context. Do not rely on it for professional, legal, medical, safety-critical, or
official translation. You are responsible for how you use AI output. We make no
warranty as to the accuracy of AI results.

10. INTELLECTUAL PROPERTY
The app, its design, code, sound, Adinkra artwork, lesson content, and trademarks
are owned by us or our licensors and are protected by law. You may not use them
except as permitted by these terms.

11. DISCLAIMERS & LIMITATION OF LIABILITY
• The app is provided "as is" and "as available", without warranties of any kind
  to the maximum extent permitted by law. We do not guarantee that learning will
  produce any particular result or that the service will be uninterrupted or
  error-free.
• To the maximum extent permitted by law, we are not liable for indirect,
  incidental, special, or consequential damages, or for loss of data, profits, or
  goodwill, arising from your use of the app.
• Nothing in these terms excludes or limits our liability where it cannot be
  excluded under Spanish or EU law — including liability for death or personal
  injury caused by negligence, fraud, or your mandatory rights as a consumer.
• Where our liability cannot lawfully be excluded but can be limited, it is
  limited to the amount you paid us in the 12 months before the event giving rise
  to the claim.

12. TERMINATION
You may stop using the app and delete your account at any time (Profile → Delete
account). We may suspend or terminate access for breach of these terms or to
comply with law. Sections that by their nature should survive termination
(e.g. intellectual property, disclaimers, liability, governing law) will survive.

13. CHANGES TO THE SERVICE AND TERMS
We may update the app and these terms. For material changes we will update the
"Last updated" date and provide notice in the app. Continued use after changes
take effect means you accept the updated terms; if you do not agree, stop using
the app.

14. GOVERNING LAW & JURISDICTION
These terms are governed by the laws of Spain. Any dispute will be subject to the
exclusive jurisdiction of the courts of the city of Barcelona, Spain — except
that, if you are a consumer, this does not deprive you of the protection of
mandatory provisions of the law of your country of residence, and you may also
bring proceedings in the courts of your domicile as permitted by EU consumer law.
EU consumers may also use the European Commission's Online Dispute Resolution
platform at ec.europa.eu/consumers/odr.

15. CONTACT
Questions about these terms: sankofa@aparato.ai
Lourette Osei Bonsu, Carrer de Maignon 34, 08024 Barcelona, Spain
''';
