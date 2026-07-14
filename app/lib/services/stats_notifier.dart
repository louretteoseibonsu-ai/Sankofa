import 'package:flutter/foundation.dart';

/// Live day-streak value so the fuel gauge can refill the instant a lesson is
/// recorded — no full reload. Updated by [ProgressService] on load and record.
final ValueNotifier<int> streakNotifier = ValueNotifier<int>(0);
