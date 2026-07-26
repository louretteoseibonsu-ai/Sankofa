import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/audio_cache.dart';
import '../services/audio_bundle.dart';
import '../services/credits_service.dart';
import '../theme.dart';
import '../widgets/credits_bar.dart';
import '../widgets/velvet.dart';
import 'upgrade_screen.dart';

/// A velvet surface card for the dark Translate hub. Tappable when [onTap] set.
Widget _velvetCard({required Widget child, VoidCallback? onTap}) {
  final decorated = Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF211B17),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
    ),
    child: child,
  );
  if (onTap == null) return decorated;
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

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _controller = TextEditingController();
  final _player = AudioPlayer();
  final _credits = CreditsService(aiCredits);
  bool _enToTw = true; // direction
  bool _loading = false;
  String? _translation;
  String? _error;
  CreditStatus? _status; // credit balance

  @override
  void initState() {
    super.initState();
    _refreshCredits();
  }

  Future<void> _refreshCredits() async {
    final s = await _credits.status();
    if (mounted) setState(() => _status = s);
  }

  /// Ensures one credit is available, consuming it. If none are left, prompts
  /// the user to buy an overage pack with pedis. Returns true to proceed.
  Future<bool> _ensureCredit() async {
    if (await _credits.tryConsume()) return true;
    final bought = await _showBuySheet();
    if (bought && await _credits.tryConsume()) return true;
    return false;
  }

  Future<void> _openBuyFromBar() async {
    await _showBuySheet();
    await _refreshCredits();
  }

  Future<bool> _showBuySheet() async {
    final s = _status ?? await _credits.status();
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
                  Text("You're out of AI credits",
                      style: displayFont(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: kVelvetInk)),
                  const SizedBox(height: 6),
                  const Text(
                      'AI credits cover translations, Lens scans and audio. They '
                      'reset next month. Top up now with $kAiCreditPackSize '
                      'credits for $kAiCreditPackPedis pedis.',
                      style: TextStyle(color: kVelvetMuted, height: 1.45)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.spa_outlined, size: 18, color: kOchre),
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
                    const Text(
                        'Not enough pedis. Earn more by completing lessons and '
                        'keeping your streak, then come back to top up.',
                        style: TextStyle(color: accentCoral, fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
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

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Spend one credit (or buy overage) before hitting the AI backend.
    final hasCredit = await _ensureCredit();
    if (!hasCredit) {
      await _refreshCredits();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _translation = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$kBackendBaseUrl/api/translate'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'mode': _enToTw ? 'en-to-twi' : 'twi-to-en'}),
      );
      if (res.statusCode != 200) {
        throw Exception('Server ${res.statusCode}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() => _translation = (data['translation'] ?? '').toString());
    } catch (e) {
      setState(() => _error = 'Translation failed. Check your connection / backend URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
      _refreshCredits(); // reflect the spent credit
    }
  }

  Future<void> _listen() async {
    final t = _translation;
    if (t == null || t.isEmpty) return;
    // Bundled clip → play free, no API call, no credit.
    final asset = await AudioBundle.instance.assetPathFor(t);
    if (asset != null) {
      try {
        await _player.play(AssetSource(asset));
      } catch (_) {}
      return;
    }
    // Cached clip replays for free; a fresh fetch is a Khaya call (1 credit).
    final cacheKey = TtsCache.instance.key(t);
    final cached = TtsCache.instance.get(cacheKey);
    if (cached != null) {
      try {
        await _player.play(BytesSource(cached));
      } catch (_) {}
      return;
    }
    if (!await _ensureCredit()) {
      await _refreshCredits();
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('$kBackendBaseUrl/api/tts'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': t, 'lang': 'tw'}),
      );
      if (res.statusCode != 200) throw Exception('tts ${res.statusCode}');
      TtsCache.instance.put(cacheKey, res.bodyBytes);
      await _player.play(BytesSource(res.bodyBytes));
      _refreshCredits();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not play Twi audio.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        Text('AI Translate',
            style: displayFont(
                fontSize: 26, fontWeight: FontWeight.w800, color: kVelvetInk)),
        const SizedBox(height: 2),
        const Text('Free to use — English ⇆ Twi with native audio.',
            style: TextStyle(color: kVelvetMuted, fontSize: 13.5)),
        const SizedBox(height: 10),
        if (_status != null)
          CreditsBar(
              status: _status!,
              unit: 'AI credits',
              onBuy: _openBuyFromBar,
              dark: true),
        // Gentle upgrade nudge — only for free users who are running low.
        if (_status != null && !_status!.premium && _status!.remaining <= 5) ...[
          const SizedBox(height: 10),
          _velvetCard(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpgradeScreen())),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: kOchre, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      _status!.remaining == 0
                          ? 'Out of credits — Premium gives 400 AI credits a month.'
                          : 'Running low — Premium gives 400 AI credits a month.',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: kVelvetInk,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          style: SegmentedButton.styleFrom(
            foregroundColor: kVelvetMuted,
            selectedForegroundColor: const Color(0xFF17130F),
            selectedBackgroundColor: kOchre,
            side: const BorderSide(color: Colors.white24),
          ),
          segments: const [
            ButtonSegment(value: true, label: Text('English → Twi')),
            ButtonSegment(value: false, label: Text('Twi → English')),
          ],
          selected: {_enToTw},
          onSelectionChanged: (s) => setState(() => _enToTw = s.first),
        ),
        const SizedBox(height: 16),
        _velvetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: kVelvetInk),
                cursorColor: kOchre,
                decoration: InputDecoration(
                  hintText: _enToTw ? 'Type English…' : 'Type Twi…',
                  hintStyle: const TextStyle(color: kVelvetMuted),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(color: Colors.white12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _loading ? null : _translate,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Translate'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: accentCoral)),
        if (_translation != null)
          _velvetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRANSLATION',
                    style: microLabel(color: kOchre)),
                const SizedBox(height: 6),
                Text(_translation!,
                    style: displayFont(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: kVelvetInk)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _listen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kVelvetInk,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  icon: const Icon(Icons.volume_up, color: kOchre),
                  label: const Text('Listen (Twi)'),
                ),
              ],
            ),
          ),
      ],
      ),
    );
  }
}

