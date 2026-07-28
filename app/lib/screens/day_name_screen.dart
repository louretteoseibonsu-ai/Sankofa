import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/akan_day_names.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/adinkra_glyph.dart';
import '../data/adinkra_symbols.dart';
import '../widgets/floating_card.dart';

class DayNameScreen extends StatefulWidget {
  const DayNameScreen({super.key});

  @override
  State<DayNameScreen> createState() => _DayNameScreenState();
}

class _DayNameScreenState extends State<DayNameScreen> {
  final _auth = AuthService();
  DateTime? _date;
  bool _male = true;

  AkanDayName? get _day {
    final d = _date;
    if (d == null) return null;
    // Dart weekday: Mon=1..Sun=7. Akan index: Sun=0..Sat=6 => weekday % 7.
    return kAkanDayNames[d.weekday % 7];
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: _velvetCalendar,
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// A coherent velvet-dark calendar so the picker isn't rendered with the
  /// half-dark Tools colour scheme (which broke it).
  static Widget _velvetCalendar(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kOchre,
            onPrimary: Color(0xFF17130F),
            surface: Color(0xFF211B17),
            onSurface: kVelvetInk,
          ),
        ),
        child: child!,
      );

  Future<void> _useAsDisplayName(String name) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to set your display name.')),
      );
      return;
    }
    try {
      await _auth.updateDisplayName(name);
      // Persist the day-name selection (and the birth date used) to the profile.
      final d = _date;
      final dobIso = d == null
          ? null
          : '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
      await _auth.saveProfile(dayName: name, dob: dobIso);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved — display name set to "$name"')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update display name.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final sankofaSvg =
        kAdinkraSymbols.firstWhere((s) => s.id == 'nyame_dua').svg;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Akan Day Name',
            style: displayFont(
                fontSize: 26, fontWeight: FontWeight.w800, color: kVelvetInk)),
        const SizedBox(height: 4),
        const Text('Your name is given by the day you were born.',
            style: TextStyle(color: kVelvetMuted, fontSize: 14.5)),
        const SizedBox(height: 16),
        FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Male')),
                  ButtonSegment(value: false, label: Text('Female')),
                ],
                selected: {_male},
                onSelectionChanged: (s) => setState(() => _male = s.first),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, color: kOchre),
                label: Text(_date == null
                    ? 'Pick your birth date'
                    : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (day != null)
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A211C),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: AdinkraGlyph(svg: sankofaSvg, size: 64),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(_male ? day.maleName : day.femaleName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 30, color: kVelvetInk)),
                ),
                Center(
                  child: Text('Born on ${day.dayTwi}',
                      style: const TextStyle(color: kVelvetMuted)),
                ),
                const SizedBox(height: 10),
                Text('Soul name: ${day.attribute}',
                    style: const TextStyle(
                        color: kOchre, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text(day.meaning, style: const TextStyle(height: 1.5, color: kVelvetInk)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _useAsDisplayName(_male ? day.maleName : day.femaleName),
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: Text(
                        'Use "${_male ? day.maleName : day.femaleName}" as my display name'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
