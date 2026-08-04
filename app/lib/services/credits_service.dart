import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

/// Configuration for one metered feature's credit bucket. State is stored on
/// users/{uid} under fields prefixed by [prefix] (e.g. tcMonth/tcUsed/tcExtra
/// for Translate, lcMonth/lcUsed/lcExtra for Lens). The pedis balance is shared.
class CreditConfig {
  final String prefix; // 'tc' (translate) | 'lc' (lens)
  final int freeAllowance;
  final int premiumAllowance;
  final int packSize; // credits per pedi-purchase
  final int packPedis; // pedi cost per pack
  final int maxMonthlyExtra; // cap on bought credits per month
  const CreditConfig({
    required this.prefix,
    required this.freeAllowance,
    required this.premiumAllowance,
    required this.packSize,
    required this.packPedis,
    required this.maxMonthlyExtra,
  });
}

/// One unified pool for every Khaya call (translate, Lens scan, audio/TTS).
const CreditConfig aiCredits = CreditConfig(
  prefix: 'ai',
  freeAllowance: kFreeMonthlyAiCredits,
  premiumAllowance: kPremiumMonthlyAiCredits,
  packSize: kAiCreditPackSize,
  packPedis: kAiCreditPackPedis,
  maxMonthlyExtra: kAiMaxMonthlyExtra,
);

/// Snapshot of a feature's credit state for the current month.
class CreditStatus {
  final int allowance; // monthly included
  final int used; // consumed this month
  final int extra; // bought with pedis this month
  final int pedis; // soft-currency balance
  final bool premium;
  final int packPedis;
  final int packSize;
  final int maxExtra;

  const CreditStatus({
    required this.allowance,
    required this.used,
    required this.extra,
    required this.pedis,
    required this.premium,
    required this.packPedis,
    required this.packSize,
    required this.maxExtra,
  });

  int get remaining {
    final r = allowance + extra - used;
    return r < 0 ? 0 : r;
  }

  bool get atCap => extra >= maxExtra;
  bool get canBuy => pedis >= packPedis && !atCap;

  CreditStatus._empty()
      : allowance = 0,
        used = 0,
        extra = 0,
        pedis = 0,
        premium = false,
        packPedis = 0,
        packSize = 0,
        maxExtra = 0;
  static final empty = CreditStatus._empty();
}

/// Meters a feature's usage against a monthly allowance and lets users buy
/// overage credits with pedis (up to a monthly cap). A change of month resets
/// used/extra automatically.
class CreditsService {
  final CreditConfig cfg;
  CreditsService(this.cfg);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _month {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  int _allowanceFor(bool premium) =>
      premium ? cfg.premiumAllowance : cfg.freeAllowance;

  Future<CreditStatus> status() async {
    final uid = _uid;
    if (uid == null) return CreditStatus.empty;
    final doc = await _db.collection('users').doc(uid).get();
    final m = doc.data() ?? {};
    final premium = (m['premium'] as bool?) ?? false;
    final sameMonth = (m['${cfg.prefix}Month'] as String?) == _month;
    return CreditStatus(
      allowance: _allowanceFor(premium),
      used: sameMonth ? ((m['${cfg.prefix}Used'] as num?)?.toInt() ?? 0) : 0,
      extra: sameMonth ? ((m['${cfg.prefix}Extra'] as num?)?.toInt() ?? 0) : 0,
      pedis: (m['pedis'] as num?)?.toInt() ?? 0,
      premium: premium,
      packPedis: cfg.packPedis,
      packSize: cfg.packSize,
      maxExtra: cfg.maxMonthlyExtra,
    );
  }

  /// Atomically consumes one credit. Returns true if one was available.
  Future<bool> tryConsume() async {
    final uid = _uid;
    if (uid == null) return false;
    final ref = _db.collection('users').doc(uid);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final m = snap.data() ?? {};
      final premium = (m['premium'] as bool?) ?? false;
      final sameMonth = (m['${cfg.prefix}Month'] as String?) == _month;
      final used =
          sameMonth ? ((m['${cfg.prefix}Used'] as num?)?.toInt() ?? 0) : 0;
      final extra =
          sameMonth ? ((m['${cfg.prefix}Extra'] as num?)?.toInt() ?? 0) : 0;
      final remaining = _allowanceFor(premium) + extra - used;
      if (remaining <= 0) return false;
      tx.set(ref, {
        '${cfg.prefix}Month': _month,
        '${cfg.prefix}Used': used + 1,
        '${cfg.prefix}Extra': extra,
      }, SetOptions(merge: true));
      return true;
    });
  }

  /// Refunds one previously-consumed credit — used when the backend call fails
  /// after the credit was spent, so a failed request never costs the user.
  /// No-op if nothing was used this month.
  Future<void> refund() async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      final m = snap.data() ?? {};
      final sameMonth = (m['${cfg.prefix}Month'] as String?) == _month;
      final used =
          sameMonth ? ((m['${cfg.prefix}Used'] as num?)?.toInt() ?? 0) : 0;
      if (used <= 0) return;
      tx.set(ref, {
        '${cfg.prefix}Month': _month,
        '${cfg.prefix}Used': used - 1,
      }, SetOptions(merge: true));
    });
  }

  /// Spends pedis for one overage pack. Returns false if the balance is too low
  /// or the monthly purchase cap is reached.
  Future<bool> buyPack() async {
    final uid = _uid;
    if (uid == null) return false;
    final ref = _db.collection('users').doc(uid);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final m = snap.data() ?? {};
      final pedis = (m['pedis'] as num?)?.toInt() ?? 0;
      if (pedis < cfg.packPedis) return false;
      final sameMonth = (m['${cfg.prefix}Month'] as String?) == _month;
      final used =
          sameMonth ? ((m['${cfg.prefix}Used'] as num?)?.toInt() ?? 0) : 0;
      final extra =
          sameMonth ? ((m['${cfg.prefix}Extra'] as num?)?.toInt() ?? 0) : 0;
      if (extra >= cfg.maxMonthlyExtra) return false;
      tx.set(ref, {
        'pedis': pedis - cfg.packPedis,
        '${cfg.prefix}Month': _month,
        '${cfg.prefix}Used': used,
        '${cfg.prefix}Extra': extra + cfg.packSize,
      }, SetOptions(merge: true));
      return true;
    });
  }
}
