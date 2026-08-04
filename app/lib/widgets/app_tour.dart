import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';
import 'tappable_scale.dart';

/// A skippable, Intercom-style first-run product tour that shows a new user
/// where the key things are: how to start a lesson, the bottom bar, and where
/// their profile lives. Pops when finished or skipped.
Future<void> showAppTour(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.66),
    builder: (_) => const _AppTour(),
  );
}

class _AppTour extends StatefulWidget {
  const _AppTour();
  @override
  State<_AppTour> createState() => _AppTourState();
}

class _AppTourState extends State<_AppTour> {
  final _pc = PageController();
  int _i = 0;
  static const _count = 4;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= _count - 1) {
      Navigator.of(context).pop();
      return;
    }
    _pc.nextPage(
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _count - 1;
    return Dialog(
      backgroundColor: const Color(0xFF211B17),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TappableScale(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded,
                    color: kVelvetMuted, size: 22),
              ),
            ),
            SizedBox(
              height: 268,
              child: PageView(
                controller: _pc,
                onPageChanged: (v) => setState(() => _i = v),
                children: const [
                  _Slide(
                    visual: _WelcomeVisual(),
                    title: 'Akwaaba! 👋',
                    body:
                        'Welcome to Sankofa Twi. Here’s the whole app in 20 '
                        'seconds — or tap Skip and explore on your own.',
                  ),
                  _Slide(
                    visual: _PlayVisual(),
                    title: 'Start a lesson',
                    body:
                        'On the Journey screen, tap the orange Play button to '
                        'begin your current lesson — short questions with real '
                        'Twi audio. Clear it to unlock the next stop.',
                  ),
                  _Slide(
                    visual: _NavVisual(),
                    title: 'Find your way around',
                    body:
                        'The bar at the bottom holds everything: Journey, '
                        'Translate, Lens, Progress and Tools.',
                  ),
                  _Slide(
                    visual: _ProfileVisual(),
                    title: 'Make it yours',
                    body:
                        'Tap your photo in the top-right corner to set your '
                        'name, pick a Super Family avatar, and find your Akan '
                        'day name.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int d = 0; d < _count; d++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: d == _i ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: d == _i ? kOchre : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!last)
                  TappableScale(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Text('Skip',
                          style: TextStyle(
                              color: kVelvetMuted, fontWeight: FontWeight.w700)),
                    ),
                  ),
                const Spacer(),
                TappableScale(
                  onTap: _next,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kOchre, Color(0xFFB5792E)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(last ? 'Done · Yɛn kɔ!' : 'Next',
                        style: const TextStyle(
                            color: Color(0xFF17130F),
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final Widget visual;
  final String title;
  final String body;
  const _Slide(
      {required this.visual, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 110, child: Center(child: visual)),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: displayFont(
                fontSize: 20, fontWeight: FontWeight.w800, color: kVelvetInk)),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: kVelvetMuted, fontSize: 13, height: 1.5)),
      ],
    );
  }
}

class _WelcomeVisual extends StatelessWidget {
  const _WelcomeVisual();
  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: terracotta.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.waving_hand_rounded, color: kOchre, size: 34),
      );
}

/// A mock of the orange Play card, with the button highlighted.
class _PlayVisual extends StatelessWidget {
  const _PlayVisual();
  @override
  Widget build(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A211C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BOSS STOP',
                      style: TextStyle(
                          color: Color(0xFFC0603A),
                          fontSize: 9,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('The Twi Alphabet',
                      style: TextStyle(
                          color: kVelvetInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFC0603A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFC0603A).withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 1),
                ],
              ),
              child: const Text('Play',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ],
        ),
      );
}

/// A mock of the 5-item bottom nav.
class _NavVisual extends StatelessWidget {
  const _NavVisual();
  static const _items = [
    (Icons.route, 'Journey', true),
    (Icons.translate, 'Translate', false),
    (Icons.center_focus_strong, 'Lens', false),
    (Icons.insights, 'Progress', false),
    (Icons.apps, 'Tools', false),
  ];
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1712),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final it in _items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(it.$1,
                        size: 20,
                        color: it.$3 ? const Color(0xFFC0603A) : kVelvetMuted),
                    const SizedBox(height: 3),
                    Text(it.$2,
                        style: TextStyle(
                            fontSize: 8.5,
                            color:
                                it.$3 ? const Color(0xFFC0603A) : kVelvetMuted)),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// A mock of the header showing the top-right avatar highlighted.
class _ProfileVisual extends StatelessWidget {
  const _ProfileVisual();
  @override
  Widget build(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A211C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Maaha, Akua',
                  style: TextStyle(
                      color: kVelvetInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.north_east_rounded, color: kOchre, size: 18),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3A2D22),
                border: Border.all(color: kOchre, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: kOchre.withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  color: kVelvetMuted, size: 20),
            ),
          ],
        ),
      );
}
