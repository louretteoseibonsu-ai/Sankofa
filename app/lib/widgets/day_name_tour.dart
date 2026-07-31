import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';
import 'tappable_scale.dart';

/// Direction B — an Intercom-style modal product tour that introduces the Akan
/// day name to new users, then hands them to the picker. Pops when finished.
Future<void> showDayNameTour(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (_) => const _DayNameTour(),
  );
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);
}

const _slides = [
  _Slide(Icons.auto_awesome_rounded, 'Meet your day name',
      'In Akan tradition, everyone carries a name for the very day they were born — your kra din, or soul name.'),
  _Slide(Icons.calendar_month_rounded, 'How it works',
      'Your birthday points to an Akan day, and each day has a name for men and women — plus a character it’s known for.'),
  _Slide(Icons.badge_rounded, 'Make it yours',
      'Pick your birth date below, then tap your name to set it as your display name across Sankofa Twi.'),
];

class _DayNameTour extends StatefulWidget {
  const _DayNameTour();
  @override
  State<_DayNameTour> createState() => _DayNameTourState();
}

class _DayNameTourState extends State<_DayNameTour> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= _slides.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _pc.nextPage(
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _slides.length - 1;
    return Dialog(
      backgroundColor: const Color(0xFF211B17),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
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
              height: 232,
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (v) => setState(() => _i = v),
                itemCount: _slides.length,
                itemBuilder: (_, i) =>
                    i == 1 ? _howItWorks(_slides[i]) : _slideView(_slides[i]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int d = 0; d < _slides.length; d++)
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
            const SizedBox(height: 18),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kOchre, Color(0xFFB5792E)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(last ? 'Let’s go' : 'Next',
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

  Widget _slideView(_Slide s) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: terracotta.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(s.icon, color: kOchre, size: 30),
        ),
        const SizedBox(height: 18),
        Text(s.title,
            textAlign: TextAlign.center,
            style: displayFont(
                fontSize: 21, fontWeight: FontWeight.w800, color: kVelvetInk)),
        const SizedBox(height: 10),
        Text(s.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: kVelvetMuted, fontSize: 13.5, height: 1.55)),
      ],
    );
  }

  Widget _howItWorks(_Slide s) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.title,
            textAlign: TextAlign.center,
            style: displayFont(
                fontSize: 21, fontWeight: FontWeight.w800, color: kVelvetInk)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _step(Icons.cake_rounded, 'Birthday'),
            _arrow(),
            _step(Icons.calendar_today_rounded, 'Akan day'),
            _arrow(),
            _step(Icons.badge_rounded, 'Your name', highlight: true),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2A211C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Text('Born on Wednesday (Wukuada) → Akua / Kwaku',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kVelvetInk, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _step(IconData icon, String label, {bool highlight = false}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2A211C),
            shape: BoxShape.circle,
            border: Border.all(
                color: highlight ? kOchre : Colors.white12,
                width: highlight ? 1.6 : 1),
          ),
          child: Icon(icon,
              color: highlight ? kOchre : kVelvetMuted, size: 20),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color: highlight ? kOchre : kVelvetMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _arrow() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 15),
      );
}
