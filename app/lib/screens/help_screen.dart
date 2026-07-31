import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;
import '../widgets/floating_card.dart';
import 'support_chat_screen.dart';

/// In-app Help Center: a searchable FAQ, a button into the AI support chat,
/// and the human support email. Mirrors docs/support_kb.md.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

const List<_Faq> _faqs = [
  _Faq(
    'Twi audio is slow or won\'t play. What do I do?',
    'Our audio service can take a few seconds to "wake up". Wait ~30 seconds and '
        'tap play again, and check your internet connection. Lesson words also '
        'play instantly from the app once downloaded. If it says you\'re out of '
        'AI credits, top up with pedis or wait for your monthly reset.',
  ),
  _Faq(
    'What are AI credits and pedis?',
    'AI Translate, Sankofa Lens and spoken audio share one monthly pool of AI '
        'credits (Premium: 400/month, Free: 15). When they run out, top up with '
        'pedis — the in-app currency you earn from lessons, streaks and Lens '
        'finds — or wait for the monthly reset.',
  ),
  _Faq(
    'Is Sankofa Twi free?',
    'Yes — core lessons, the first 10 Adinkra symbols, streaks, daily quests, '
        'and AI Translate (with free monthly credits) are all free. Premium '
        'unlocks every lesson, all symbols, many more AI credits, and the full '
        'Lens experience.',
  ),
  _Faq(
    'How much is Premium?',
    'Premium is €6.99/month or €59.99/year (shown in your local currency), with '
        'a 7-day free trial. Note: paid plans are launching soon.',
  ),
  _Faq(
    'How do I use Sankofa Lens?',
    'Open Tools → Lens, tap "Point & capture", and Lens names the object in Twi. '
        'Tap "Say it out loud" to hear it, and "Save" to add it to your visual '
        'dictionary. If it says recognition failed, enable the Camera permission '
        'for Sankofa Twi in your phone Settings.',
  ),
  _Faq(
    'I didn\'t get my verification email.',
    'Check your spam/junk folder first. Then open Profile and tap "Resend" on '
        'the verify-email banner. Make sure your email address is spelled '
        'correctly.',
  ),
  _Faq(
    'How do I reset my password?',
    'On the sign-in screen, tap "Forgot password?", enter your email, and we\'ll '
        'send you a reset link.',
  ),
  _Faq(
    'How do I delete my account?',
    'Go to Profile → Delete account. This permanently removes your account and '
        'all your data and cannot be undone. You\'ll confirm with your password '
        '(or Google).',
  ),
  _Faq(
    'How do I cancel Premium?',
    'Manage or cancel in your Google Play or Apple App Store subscription '
        'settings; access continues until the end of the paid period. (Paid '
        'plans are launching soon.)',
  ),
];

class _HelpScreenState extends State<HelpScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final faqs = q.isEmpty
        ? _faqs
        : _faqs
            .where((f) =>
                f.q.toLowerCase().contains(q) || f.a.toLowerCase().contains(q))
            .toList();

    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),

      appBar: AppBar(title: const Text('Help & support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chat with us
            FloatingCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SupportChatScreen())),
              child: const Row(
                children: [
                  Icon(Icons.support_agent, color: terracotta, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat with support',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: kVelvetInk)),
                        Text('Ask our assistant anything — instant answers',
                            style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white30),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Frequently asked',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search help…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (faqs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                    'No matches. Try the chat above, or email us below.',
                    style: TextStyle(color: kVelvetMuted)),
              )
            else
              ...faqs.map((f) => Card(
                    elevation: 0,
                    color: const Color(0xFF211B17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.white10)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(f.q,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: kVelvetInk)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(f.a,
                              style: const TextStyle(
                                  color: kVelvetMuted, height: 1.45, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 16),
            // Email us
            const FloatingCard(
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 20, color: kVelvetInk),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still need help? Email us',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: kVelvetInk)),
                        Text('sankofa@aparato.ai',
                            style: TextStyle(color: kVelvetMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }
}
