import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_drills.dart';
import '../services/twi_speech.dart';
import '../theme.dart';
import 'floating_card.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

const Color _tileBg = Color(0xFF211B17);
const Color _green = Color(0xFF63C583);
const Color _greenBg = Color(0xFF17281C);
const Color _red = Color(0xFFE0655A);
const Color _redBg = Color(0xFF2C1D18);

/// A round "play the Twi audio" button used by the listen + build drills.
class _SpeakChip extends StatelessWidget {
  final String text;
  final double size;
  const _SpeakChip({required this.text, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: InkResponse(
        radius: 28,
        onTap: () => TwiSpeech.instance.speak(text),
        child: Center(
          child: Icon(Icons.volume_up_rounded, size: size, color: terracotta),
        ),
      ),
    );
  }
}

Widget _kicker(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(s.toUpperCase(),
          style: const TextStyle(
              color: kVelvetMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.1)),
    );

// ════════════════════════ WORD MATCH ════════════════════════

class MatchDrillView extends StatefulWidget {
  final MatchDrill data;
  final ValueChanged<bool> onAnswered;
  const MatchDrillView({super.key, required this.data, required this.onAnswered});

  @override
  State<MatchDrillView> createState() => _MatchDrillViewState();
}

class _MatchDrillViewState extends State<MatchDrillView> {
  late final List<String> _twi;
  late final List<String> _en;
  final Set<String> _done = {}; // twi ids matched
  final Set<String> _enDone = {};
  String? _selTwi;
  String? _wrongEn;
  int _mistakes = 0;
  bool _finished = false;

  String _enFor(String twi) => widget.data.pairs.firstWhere((p) => p.twi == twi).en;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _twi = [for (final p in widget.data.pairs) p.twi]..shuffle(r);
    _en = [for (final p in widget.data.pairs) p.en]..shuffle(r);
  }

  void _tapEn(String en) {
    if (_selTwi == null || _enDone.contains(en)) return;
    if (_enFor(_selTwi!) == en) {
      setState(() {
        _done.add(_selTwi!);
        _enDone.add(en);
        _selTwi = null;
      });
      if (_done.length == widget.data.pairs.length && !_finished) {
        _finished = true;
        HapticFeedback.mediumImpact();
        widget.onAnswered(_mistakes == 0);
      }
    } else {
      _mistakes++;
      HapticFeedback.heavyImpact();
      setState(() => _wrongEn = en);
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted) setState(() => _wrongEn = null);
      });
    }
  }

  Widget _cell(String label,
      {required bool matched,
      required bool selected,
      required bool wrong,
      VoidCallback? onTap}) {
    Color bg = _tileBg, border = const Color(0x3DFFFFFF), fg = kVelvetInk;
    if (matched) {
      bg = _greenBg;
      border = _green;
      fg = _green;
    } else if (selected) {
      border = kOchre;
      fg = kOchre;
    } else if (wrong) {
      bg = _redBg;
      border = _red;
      fg = _red;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TappableScale(
        onTap: matched ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w600, fontSize: 14.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kicker('Match the pairs'),
          const Text('Tap a Twi word, then its English meaning.',
              style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final t in _twi)
                      _cell(t,
                          matched: _done.contains(t),
                          selected: _selTwi == t,
                          wrong: false,
                          onTap: () => setState(() => _selTwi = t)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final e in _en)
                      _cell(e,
                          matched: _enDone.contains(e),
                          selected: false,
                          wrong: _wrongEn == e,
                          onTap: () => _tapEn(e)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════ LISTEN & CHOOSE ════════════════════════

class ListenDrillView extends StatefulWidget {
  final ListenDrill data;
  final ValueChanged<bool> onAnswered;
  const ListenDrillView(
      {super.key, required this.data, required this.onAnswered});

  @override
  State<ListenDrillView> createState() => _ListenDrillViewState();
}

class _ListenDrillViewState extends State<ListenDrillView> {
  String? _picked;

  @override
  void initState() {
    super.initState();
    // Auto-play the prompt once when the drill appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TwiSpeech.instance.speak(widget.data.answer.audio ?? widget.data.answer.twi);
    });
  }

  void _choose(String en) {
    if (_picked != null) return;
    final correct = en == widget.data.answer.en;
    setState(() => _picked = en);
    HapticFeedback.selectionClick();
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final answered = _picked != null;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kicker('Listen & choose'),
          Row(
            children: [
              _SpeakChip(
                  text: widget.data.answer.audio ?? widget.data.answer.twi,
                  size: 30),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Tap ▶ to hear it again — what does it mean?',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in widget.data.options)
            _OptTile(
              label: e,
              state: !answered
                  ? _OptState.idle
                  : e == widget.data.answer.en
                      ? _OptState.correct
                      : e == _picked
                          ? _OptState.wrong
                          : _OptState.dimmed,
              onTap: answered ? null : () => _choose(e),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════ BUILD THE SENTENCE ════════════════════════

class BuildDrillView extends StatefulWidget {
  final BuildDrill data;
  final ValueChanged<bool> onAnswered;
  const BuildDrillView(
      {super.key, required this.data, required this.onAnswered});

  @override
  State<BuildDrillView> createState() => _BuildDrillViewState();
}

class _BuildDrillViewState extends State<BuildDrillView> {
  late final List<String> _scrambled;
  final List<int> _placed = []; // indices into _scrambled, in placed order
  bool _finished = false;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _scrambled = [...widget.data.tokens]..shuffle(r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TwiSpeech.instance.speak(widget.data.audio);
    });
  }

  void _place(int i) {
    if (_placed.contains(i) || _finished) return;
    setState(() => _placed.add(i));
    if (_placed.length == widget.data.tokens.length) _check();
  }

  void _removeAt(int pos) {
    if (_finished) return;
    setState(() => _placed.removeAt(pos));
  }

  void _check() {
    final built = [for (final i in _placed) _scrambled[i]];
    final ok = built.join(' ') == widget.data.tokens.join(' ');
    setState(() {
      _finished = true;
      _correct = ok;
    });
    HapticFeedback.mediumImpact();
    widget.onAnswered(ok);
  }

  @override
  Widget build(BuildContext context) {
    Color ansBorder = const Color(0x3DFFFFFF);
    if (_correct == true) ansBorder = _green;
    if (_correct == false) ansBorder = _red;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kicker('Build the sentence'),
          Row(
            children: [
              _SpeakChip(text: widget.data.audio, size: 30),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Tap the words in order to match what you hear.',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Answer line
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF17130F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ansBorder, width: 1.4),
            ),
            child: _placed.isEmpty
                ? const Text('tap the words below…',
                    style: TextStyle(color: kVelvetMuted, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int pos = 0; pos < _placed.length; pos++)
                        _wordChip(_scrambled[_placed[pos]],
                            onTap: () => _removeAt(pos)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          // Word bank
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _scrambled.length; i++)
                if (!_placed.contains(i))
                  _wordChip(_scrambled[i], onTap: () => _place(i)),
            ],
          ),
          // On completion, reveal the sentence + a literal word-by-word gloss.
          if (_finished) ...[
            const SizedBox(height: 12),
            Text(widget.data.audio,
                style: const TextStyle(
                    color: kVelvetInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 3),
            Text('≈ ${widget.data.literalGloss()}',
                style: const TextStyle(
                    color: kVelvetMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _wordChip(String w, {VoidCallback? onTap}) => TappableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: _tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x3DFFFFFF), width: 1.2),
          ),
          child: Text(w,
              style: const TextStyle(
                  color: kVelvetInk, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      );
}

// A shared answer tile with the arcade pop/glow/shake (used by listen drill).
enum _OptState { idle, correct, wrong, dimmed }

class _OptTile extends StatefulWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptTile({required this.label, required this.state, this.onTap});

  @override
  State<_OptTile> createState() => _OptTileState();
}

class _OptTileState extends State<_OptTile> with TickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 440));

  @override
  void didUpdateWidget(covariant _OptTile old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      if (widget.state == _OptState.correct) _pop.forward(from: 0);
      if (widget.state == _OptState.wrong) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = const Color(0x3DFFFFFF), bg = _tileBg, fg = kVelvetInk;
    Widget? trailing;
    List<BoxShadow>? glow;
    switch (widget.state) {
      case _OptState.idle:
        break;
      case _OptState.correct:
        border = _green;
        bg = _greenBg;
        fg = _green;
        trailing = const Icon(Icons.check_circle, color: _green, size: 20);
        glow = [
          BoxShadow(
              color: _green.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -4),
        ];
        break;
      case _OptState.wrong:
        border = _red;
        bg = _redBg;
        fg = _red;
        trailing = const Icon(Icons.cancel, color: _red, size: 20);
        break;
      case _OptState.dimmed:
        border = const Color(0x1FFFFFFF);
        fg = kVelvetMuted;
        break;
    }
    final tile = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.4),
        boxShadow: glow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _shake]),
        builder: (_, child) {
          final pop = 1 + 0.06 * sin(pi * _pop.value);
          final dx = _shake.value > 0
              ? sin(_shake.value * pi * 8) * 7 * (1 - _shake.value)
              : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: pop, child: child),
          );
        },
        child: TappableScale(onTap: widget.onTap, child: tile),
      ),
    );
  }
}
