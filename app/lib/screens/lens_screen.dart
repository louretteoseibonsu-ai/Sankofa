import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../data/lens_collections.dart';
import '../services/audio_bundle.dart';
import '../services/audio_cache.dart';
import '../services/audio_playback.dart';
import '../services/auth_service.dart';
import '../services/credits_service.dart';
import '../services/lens_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/credits_bar.dart';
import '../widgets/velvet.dart';
import '../widgets/premium_lock.dart';

/// A velvet surface card for the dark Lens hub. Tappable when [onTap] is set.
class _VCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _VCard({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: const Color(0xFF211B17),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
    );
    if (onTap == null) {
      return Container(
          padding: const EdgeInsets.all(16), decoration: decoration, child: child);
    }
    return Material(
      color: const Color(0xFF211B17),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: kOchre.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Sankofa Lens — point the camera at any object, get its Twi name + audio you
/// can play out loud to communicate, and collect it in your visual dictionary.
class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  final _lens = LensService.instance;
  final _player = AudioPlayer();
  final _credits = CreditsService(aiCredits);
  CreditStatus? _creditStatus;

  bool? _premium; // null = checking
  bool _busy = false;
  String? _busyMsg;
  String? _error;

  File? _image;
  List<LensLabel> _labels = [];
  int _selected = 0;
  String? _twi;
  bool _twiUnavailable = false; // translation failed/empty — offer retry

  // Manual correction: shown when Lens found nothing, or nothing right, for
  // the current photo. Feeds the typed word into the normal translate/save
  // flow and logs it so maintainers can grow the recognized vocabulary.
  bool _manualEntryOpen = false;
  final TextEditingController _manualController = TextEditingController();

  // Celebration tracking: which badges/collections we've already acknowledged,
  // so we only fire confetti + sound on a *new* unlock during this session.
  StreamSubscription<List<LensFind>>? _findsSub;
  Set<String> _seenMilestones = {};
  Set<String> _seenCollections = {};
  bool _seenInit = false;

  @override
  void initState() {
    super.initState();
    AuthService().isPremium().then((v) {
      if (mounted) setState(() => _premium = v);
    });
    _findsSub = _lens.finds().listen(_onFinds);
    _refreshCredits();
  }

  Future<void> _refreshCredits() async {
    final s = await _credits.status();
    if (mounted) setState(() => _creditStatus = s);
  }

  /// Consumes one Lens scan credit; if none remain, offers a pedis top-up.
  Future<bool> _ensureCredit() async {
    if (await _credits.tryConsume()) return true;
    final bought = await _showBuySheet();
    if (bought && await _credits.tryConsume()) return true;
    return false;
  }

  Future<bool> _showBuySheet() async {
    final s = _creditStatus ?? await _credits.status();
    if (!mounted) return false;
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: const Color(0xFF1E1A17),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("You're out of AI credits",
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: kVelvetInk)),
                  const SizedBox(height: 6),
                  const Text(
                      'AI credits cover Lens scans, translations and audio. They '
                      'reset next month. Top up now with $kAiCreditPackSize '
                      'credits for $kAiCreditPackPedis pedis.',
                      style: TextStyle(color: kVelvetMuted, height: 1.45)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.spa_outlined,
                          size: 18, color: const Color(0xFF63C583)),
                      const SizedBox(width: 6),
                      Text('You have ${s.pedis} pedis',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: kVelvetInk)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (s.canBuy)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final ok = await _credits.buyPack();
                          if (context.mounted) Navigator.pop(ctx, ok);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Buy $kAiCreditPackSize credits · '
                            '$kAiCreditPackPedis pedis'),
                      ),
                    )
                  else ...[
                    Text(
                        s.atCap
                            ? "You've hit this month's top-up limit. Credits "
                                'reset next month.'
                            : 'Not enough pedis. Earn more by completing '
                                'lessons and keeping your streak, then top up.',
                        style: const TextStyle(
                            color: accentCoral, fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kVelvetInk,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text('Got it'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _openBuyFromBar() async {
    await _showBuySheet();
    await _refreshCredits();
  }

  @override
  void dispose() {
    _findsSub?.cancel();
    _player.dispose();
    _manualController.dispose();
    super.dispose();
  }

  /// Watches the finds stream and celebrates the moment a badge milestone is
  /// reached or a collection is completed.
  void _onFinds(List<LensFind> finds) {
    final total = finds.length;
    final labels = finds.map((f) => f.english).toList();
    final milestones = kLensMilestones
        .where((m) => total >= m.threshold)
        .map((m) => m.name)
        .toSet();
    final collections = kLensCollections
        .where((c) => collectionCount(c, labels) >= c.goal)
        .map((c) => c.id)
        .toSet();

    // First emission just establishes the baseline — never celebrate on load.
    if (!_seenInit) {
      _seenInit = true;
      _seenMilestones = milestones;
      _seenCollections = collections;
      return;
    }
    final newMilestones = milestones.difference(_seenMilestones);
    final newCollections = collections.difference(_seenCollections);
    _seenMilestones = milestones;
    _seenCollections = collections;
    if (newMilestones.isNotEmpty || newCollections.isNotEmpty) {
      _celebrate(newMilestones, newCollections);
    }
  }

  void _celebrate(Set<String> badges, Set<String> collections) {
    if (!mounted) return;
    SoundService.instance.complete();
    celebrateBurst(context);
    final parts = <String>[
      ...collections.map((id) =>
          '${kLensCollections.firstWhere((c) => c.id == id).name} collection complete'),
      ...badges.map((n) => '$n badge unlocked'),
    ];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: charcoal,
      content: Text('🎉 ${parts.join('  ·  ')}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
    ));
  }

  Future<void> _capture(ImageSource src) async {
    XFile? x;
    try {
      x = await ImagePicker()
          .pickImage(source: src, maxWidth: 1024, imageQuality: 85);
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final denied = code.contains('denied') ||
          code.contains('access') ||
          code.contains('permission');
      setState(() => _error = denied
          ? (src == ImageSource.camera
              ? 'Camera access is off. Enable the camera for Sankofa Twi in '
                  'your phone Settings → Apps → Permissions, then try again.'
              : 'Photo access is off. Enable photos for Sankofa Twi in your '
                  'phone Settings → Apps → Permissions, then try again.')
          : 'Could not open the camera. Please try again.');
      return;
    }
    if (x == null) return; // user cancelled the picker
    final file = File(x.path);
    setState(() {
      _image = file;
      _labels = [];
      _twi = null;
      _twiUnavailable = false;
      _error = null;
      _manualEntryOpen = false;
      _busy = true;
      _busyMsg = 'Looking…';
    });

    // Stage 1 — on-device recognition only. Kept separate from the credit
    // check and translation below so a Firestore/network hiccup downstream
    // is never misreported as a recognition failure.
    List<LensLabel> labels;
    try {
      labels = await _lens.label(file);
    } catch (e, st) {
      debugPrint('Sankofa Lens recognition error: $e\n$st');
      setState(() {
        _busy = false;
        _error = 'Recognition failed. Please try again, or add the word '
            'yourself below.';
      });
      return;
    }

    if (labels.isEmpty) {
      setState(() {
        _busy = false;
        _error = "Couldn't quite tell what that is. Try getting closer, "
            "framing one object, or add it yourself below.";
      });
      return;
    }

    // Stage 2 — spend one Lens credit. Errors here are a credits/network
    // problem, not a recognition problem, so they get their own message.
    bool hasCredit;
    try {
      hasCredit = await _ensureCredit();
    } catch (e, st) {
      debugPrint('Sankofa Lens credit-check error: $e\n$st');
      setState(() {
        _busy = false;
        _error = "Couldn't check your AI credits — check your connection "
            "and try again.";
      });
      return;
    }
    if (!hasCredit) {
      await _safeRefreshCredits();
      setState(() {
        _busy = false;
        _error = "You're out of AI credits this month. Top up with pedis, "
            "or they reset next month.";
      });
      return;
    }

    // Stage 3 — show the recognised labels and fetch the Twi translation.
    // _translateSelected() catches its own errors internally (surfaced via
    // _twiUnavailable), so nothing from here should escape this method.
    setState(() {
      _labels = labels.take(3).toList();
      _selected = 0;
    });
    await _translateSelected();
    await _safeRefreshCredits();
  }

  /// Refreshes the credits bar without letting a network blip surface as an
  /// error — by the time this runs, the scan itself already succeeded.
  Future<void> _safeRefreshCredits() async {
    try {
      await _refreshCredits();
    } catch (e) {
      debugPrint('Sankofa Lens credits-refresh error: $e');
    }
  }

  /// User-typed correction: used when Lens found nothing, or nothing right,
  /// for the current photo. Feeds straight into the normal translate/save
  /// flow — like picking one of the suggestion chips — and logs the
  /// correction (best-effort) so it can help grow the recognized vocabulary.
  Future<void> _submitManual() async {
    final text = _manualController.text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_lens.submitCorrection(
      userLabel: text,
      suggestedLabels: _labels.map((l) => l.label).toList(),
    ));
    setState(() {
      _labels = [
        LensLabel(text, 1.0),
        ..._labels.where((l) => l.label.toLowerCase() != text.toLowerCase()),
      ].take(4).toList();
      _selected = 0;
      _manualEntryOpen = false;
      _manualController.clear();
      _error = null;
    });
    await _translateSelected();
  }

  Future<void> _translateSelected() async {
    final english = _labels[_selected].label;
    setState(() {
      _busy = true;
      _busyMsg = 'Finding the Twi…';
      _twi = null;
      _twiUnavailable = false;
    });
    try {
      final twi = await _lens.toTwi(english);
      setState(() {
        _busy = false;
        if (twi.isEmpty) {
          _twi = null;
          _twiUnavailable = true;
        } else {
          _twi = twi;
          _twiUnavailable = false;
        }
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _twi = null;
        _twiUnavailable = true;
      });
    }
  }

  Future<void> _say() async {
    final twi = _twi;
    if (twi == null) return;
    await _playTwi(twi);
  }

  /// Plays Twi audio. A cached clip replays for free; a fresh fetch is a Khaya
  /// call and spends one AI credit. Shared by the result card and dictionary.
  Future<void> _playTwi(String twi) async {
    if (twi.isEmpty) return;
    // Bundled clip → play free, no API call, no credit.
    final asset = await AudioBundle.instance.assetPathFor(twi);
    if (asset != null) {
      try {
        await _player.play(AssetSource(asset));
      } catch (_) {}
      return;
    }
    final cacheKey = TtsCache.instance.key(twi);
    final cached = TtsCache.instance.get(cacheKey);
    if (cached != null) {
      await playBytes(_player, cached); // free replay
      return;
    }
    if (!await _ensureCredit()) {
      await _refreshCredits();
      return;
    }
    try {
      final bytes = await _lens.tts(twi);
      TtsCache.instance.put(cacheKey, bytes);
      await playBytes(_player, bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play Twi audio.')));
      }
    } finally {
      _refreshCredits();
    }
  }

  Future<void> _save() async {
    if (_labels.isEmpty) return;
    final twi = _twi ?? '';
    final english = _labels[_selected].label;
    try {
      final first = await _lens.saveFind(english, twi);
      if (first) await ProgressService().addPedis(10);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(first
              ? 'First find! "$english" added · +10 pedis 🎉'
              : 'Saved to your dictionary.')));
    } catch (e) {
      if (!mounted) return;
      final isPerm = e.toString().toLowerCase().contains('permission');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(isPerm
            ? "Can't save yet — deploy the updated Firestore rules "
                "(finds subcollection). Run: firebase deploy --only "
                "firestore:rules"
            : 'Could not save: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_premium == null) {
      return const ColoredBox(
        color: Color(0xFF17130F),
        child: Center(
            child: CircularProgressIndicator(color: Color(0xFFD4A373))),
      );
    }
    final unlocked = kEverythingFree || _premium == true || kLensFreeDuringTesting;
    if (!unlocked) {
      return const PremiumLock(
        title: 'Sankofa Lens is a Premium tool',
        message:
            'Point your camera at anything and learn — and say — its Twi name. '
            'Unlock Lens with Premium, plus every lesson, symbol, and AI tool.',
        icon: Icons.center_focus_strong,
        dark: true,
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kVelvetInk,
            side: const BorderSide(color: Colors.white24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kOchre),
        ),
        chipTheme: Theme.of(context).chipTheme.copyWith(
              backgroundColor: const Color(0xFF2A211C),
              selectedColor: kOchre,
              labelStyle: const TextStyle(color: kVelvetInk),
              secondaryLabelStyle: const TextStyle(color: Color(0xFF17130F)),
              side: const BorderSide(color: Colors.white24),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A211C),
          hintStyle: const TextStyle(color: kVelvetMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17130F), Color(0xFF1E1A17)],
          ),
        ),
        child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Sankofa Lens',
                style: displayFont(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kVelvetInk)),
            const SizedBox(width: 10),
            if (_premium != true && kLensFreeDuringTesting)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFE3A92C),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Premium · free in testing',
                    style: TextStyle(
                        color: Color(0xFF2B2B2D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Point. Learn. Speak — show & say it to a Twi speaker.',
            style: TextStyle(color: kVelvetMuted, fontSize: 14.5)),
        const SizedBox(height: 14),
        if (_creditStatus != null)
          CreditsBar(
              status: _creditStatus!,
              unit: 'AI credits',
              onBuy: _openBuyFromBar,
              dark: true),
        const SizedBox(height: 14),

        // Capture buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _capture(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Point & capture'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _capture(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(_image!,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ),

        if (_busy) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(_busyMsg ?? 'Working…',
                  style: const TextStyle(color: kVelvetMuted)),
            ],
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: accentCoral)),
          const SizedBox(height: 8),
          _manualEntryToggle(),
          if (_manualEntryOpen) _manualEntryField(),
        ],

        // Result — Twi found, or a graceful "unavailable" fallback
        if (_labels.isNotEmpty && !_busy && (_twi != null || _twiUnavailable)) ...[
          const SizedBox(height: 16),
          _VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'It looks like: ${_labels[_selected].label} '
                    '(${(_labels[_selected].confidence * 100).round()}%)',
                    style: const TextStyle(
                        color: const Color(0xFF63C583),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 8),
                if (_twi != null) ...[
                  Text(_twi!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: kVelvetInk)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _say,
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Say it out loud'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text("Twi translation isn't available right now.",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: kVelvetInk)),
                  const SizedBox(height: 4),
                  const Text(
                      'The translator may be waking up or offline. You can '
                      'retry, or save the object and add the Twi later.',
                      style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _translateSelected,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save anyway'),
                      ),
                    ],
                  ),
                ],
                if (_labels.length > 1) ...[
                  const SizedBox(height: 14),
                  const Text('Not quite? Try:',
                      style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < _labels.length; i++)
                        ChoiceChip(
                          label: Text(_labels[i].label),
                          selected: i == _selected,
                          onSelected: (_) {
                            setState(() => _selected = i);
                            _translateSelected();
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _manualEntryToggle(label: 'None of these — type it'),
                if (_manualEntryOpen) _manualEntryField(),
              ],
            ),
          ),
        ],

        const SizedBox(height: 26),
        StreamBuilder<List<LensFind>>(
          stream: _lens.finds(),
          builder: (context, snap) {
            final finds = snap.data ?? const [];
            final englishLabels = finds.map((f) => f.english).toList();
            final total = finds.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badgesRow(total),
                const SizedBox(height: 22),
                const Text('Collections',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
                const SizedBox(height: 4),
                const Text('Fill each set by finding its objects in the world.',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                const SizedBox(height: 12),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 86, // fixed height — fits content on any width
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  children: [
                    for (final c in kLensCollections)
                      _collectionTile(c, collectionCount(c, englishLabels)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Your visual dictionary',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
                const SizedBox(height: 4),
                const Text('Tap any object to hear it again.',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                const SizedBox(height: 12),
                if (finds.isEmpty)
                  const Text('No finds yet — capture your first object!',
                      style: TextStyle(color: kVelvetMuted))
                else
                  for (final f in finds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VCard(
                        onTap: f.twi.isEmpty ? null : () => _playTwi(f.twi),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.twi.isEmpty ? f.english : f.twi,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: kVelvetInk)),
                                  Text(
                                      f.twi.isEmpty
                                          ? 'Twi pending — tap Retry next time'
                                          : f.english,
                                      style: const TextStyle(
                                          color: kVelvetMuted, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Icon(
                                f.twi.isEmpty
                                    ? Icons.hourglass_empty
                                    : Icons.volume_up,
                                color: f.twi.isEmpty ? kVelvetMuted : const Color(0xFF63C583),
                                size: 20),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
        ),
      ),
    );
  }

  /// Link that reveals the manual-correction text field. Reused in the error
  /// state (nothing recognised) and the results card (recognised, but wrong).
  Widget _manualEntryToggle({String label = 'Type what it is instead'}) {
    if (_manualEntryOpen) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _manualEntryOpen = true),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: Text(label),
      ),
    );
  }

  /// Text field + submit for typing the correct object name. Wires into the
  /// same translate/save flow as a recognised label.
  Widget _manualEntryField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _manualController,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: kVelvetInk),
              cursorColor: kOchre,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'e.g. fan',
              ),
              onSubmitted: (_) => _submitManual(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submitManual,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _badgesRow(int total) {
    final earned =
        kLensMilestones.where((m) => total >= m.threshold).toList();
    final next = kLensMilestones.firstWhere((m) => total < m.threshold,
        orElse: () => kLensMilestones.last);
    final allEarned = total >= kLensMilestones.last.threshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
        const SizedBox(height: 10),
        if (earned.isEmpty)
          const Text('Save your first find to earn a badge.',
              style: TextStyle(color: kVelvetMuted, fontSize: 12.5))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in earned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3A92C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 15, color: const Color(0xFF2B2B2D)),
                      const SizedBox(width: 6),
                      Text(m.name,
                          style: const TextStyle(
                              color: Color(0xFF2B2B2D),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        if (!allEarned) ...[
          const SizedBox(height: 8),
          Text('Next: ${next.name} — ${next.threshold - total} more to go',
              style: const TextStyle(color: kVelvetMuted, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _collectionTile(LensCollection c, int count) {
    final done = count >= c.goal;
    final progress = (count / c.goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: done ? const Color(0xFF63C583) : Colors.white10,
            width: done ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(c.icon,
                  size: 18, color: done ? const Color(0xFF63C583) : kVelvetInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kVelvetInk)),
              ),
              if (done)
                const Icon(Icons.check_circle, size: 16, color: const Color(0xFF63C583)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation(
                  done ? const Color(0xFF63C583) : terracotta),
            ),
          ),
          const SizedBox(height: 4),
          Text('$count / ${c.goal}',
              style: const TextStyle(color: kVelvetMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
