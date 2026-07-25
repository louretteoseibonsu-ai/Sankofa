import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/greeting.dart';
import '../widgets/tappable_scale.dart';

/// One-time "why are you learning Twi?" onboarding. Captures the learner's
/// motivation + region so we can tailor the experience (and it's warm, on-brand
/// heritage framing rather than a form).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _auth = AuthService();
  int _step = 0;
  String? _intent;
  String? _region;
  bool _saving = false;

  static const _intents = [
    ('family', Icons.favorite_rounded, 'Connect with family',
        'Speak with parents, grandparents, and relatives'),
    ('roots', Icons.public_rounded, 'Reclaim my roots',
        'Learn the language of home and heritage'),
    ('travel', Icons.flight_takeoff_rounded, 'Travel to Ghana',
        'Get around and greet people with confidence'),
    ('culture', Icons.music_note_rounded, 'Love the culture',
        'Afrobeats, film, food — go deeper'),
  ];

  static const _regions = [
    ('us', 'United States'),
    ('uk', 'United Kingdom'),
    ('ca', 'Canada'),
    ('gh', 'Ghana'),
    ('other', 'Somewhere else'),
  ];

  Future<void> _finish() async {
    setState(() => _saving = true);
    await _auth.saveOnboarding(
        intent: _intent ?? 'roots', region: _region ?? 'other');
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final name = firstNameOf(FirebaseAuth.instance.currentUser);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // progress dots
              Row(children: [
                for (int i = 0; i < 2; i++) ...[
                  Container(
                    width: i == _step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: i <= _step ? terracottaDeep : silverLight,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 6),
                ],
              ]),
              const SizedBox(height: 28),
              if (_step == 0) ...[
                Text('Akwaaba, $name 🇬🇭',
                    style: displayFont(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('What brings you to Twi?',
                    style: TextStyle(color: slate, fontSize: 15)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      for (final it in _intents)
                        _OptionCard(
                          icon: it.$2,
                          title: it.$3,
                          subtitle: it.$4,
                          selected: _intent == it.$1,
                          onTap: () => setState(() => _intent = it.$1),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Where are you based?',
                    style: displayFont(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('So we can tailor examples and timing.',
                    style: TextStyle(color: slate, fontSize: 15)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      for (final r in _regions)
                        _OptionCard(
                          title: r.$2,
                          selected: _region == r.$1,
                          onTap: () => setState(() => _region = r.$1),
                        ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          if (_step == 0) {
                            if (_intent == null) return;
                            setState(() => _step = 1);
                          } else {
                            if (_region == null) return;
                            _finish();
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_step == 0 ? 'Continue' : "Let's go — Yɛn kɔ!"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard({
    this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TappableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF7E6DF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? terracottaDeep : silverLight,
                width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: selected ? terracottaDeep : charcoal, size: 24),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ink)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style:
                              const TextStyle(color: slate, fontSize: 12.5)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: terracottaDeep, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
