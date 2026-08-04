import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// UI + game audio. Sampled cues played at low latency, paired with
/// HapticFeedback for a premium, tactile feel.
///
/// Channels:
///  • [_ui]    — the single-shot UI player (correct/complete/tap). Each
///               call stops the previous, so quick UI blips never pile up.
///  • [_fxPool] — a small round-robin pool for the unboxing one-shots (tap,
///               tick, burst, reveal, collect) so LAYERED cues can ring out at
///               once instead of clobbering each other (arcade stacking).
///  • [_riser] — a dedicated channel for the sustained ignition swell, so it
///               can build underneath the shorter one-shots without being cut.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Toggle to mute all sounds app-wide (e.g. from a settings switch later).
  bool enabled = true;

  final AudioPlayer _ui = AudioPlayer(playerId: 'sankofa_ui')
    ..setReleaseMode(ReleaseMode.stop);

  // Round-robin pool of independent players for overlapping game one-shots.
  static const int _poolSize = 4;
  late final List<AudioPlayer> _fxPool = List.generate(
    _poolSize,
    (i) => AudioPlayer(playerId: 'sankofa_fx_$i')
      ..setReleaseMode(ReleaseMode.stop),
  );
  int _next = 0;

  final AudioPlayer _riser = AudioPlayer(playerId: 'sankofa_riser')
    ..setReleaseMode(ReleaseMode.stop);

  // Dedicated looping music channel (the Afrobeat celebration groove), with a
  // manual volume ramp so it can fade in on mount and out on navigate-away.
  final AudioPlayer _music = AudioPlayer(playerId: 'sankofa_music')
    ..setReleaseMode(ReleaseMode.loop);
  Timer? _musicFade;
  double _musicVol = 0.0;

  Future<void> _play(String file, double volume) async {
    if (!enabled) return;
    try {
      await _ui.stop();
      await _ui.play(AssetSource('sfx/$file'),
          volume: volume, mode: PlayerMode.lowLatency);
    } catch (_) {
      // never let a missing sound break the UI
    }
  }

  /// Fire a one-shot on the next free pool player (does NOT stop the others),
  /// so cues can stack. Optional [rate] pitches the sample up for variation.
  Future<void> _fx(String file, double volume, {double rate = 1.0}) async {
    if (!enabled) return;
    final p = _fxPool[_next];
    _next = (_next + 1) % _poolSize;
    try {
      await p.stop();
      if (rate != 1.0) await p.setPlaybackRate(rate);
      await p.play(AssetSource('sfx/$file'),
          volume: volume, mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  // ── UI sounds ──────────────────────────────────────────────────────────
  /// Correct-answer pluck (kalimba). Climbs the scale with the combo [step] —
  /// the higher your streak, the higher the note. That rising reward is the
  /// addictive hook (Mario-coin / Duolingo-combo effect).
  Future<void> correct({int step = 0}) =>
      _play('correct_${step.clamp(0, 7)}.wav', 0.6);

  /// A soft, non-punishing descending "aw" for a wrong answer — never a harsh
  /// buzzer, so a miss nudges rather than demoralises.
  Future<void> wrong() => _play('wrong.wav', 0.5);
  Future<void> complete() => _play('complete.wav', 0.6);
  Future<void> tap() => _play('tap.wav', 0.35);

  // ── Blind-box unboxing cues (synced to the 4-phase timeline) ────────────
  /// Phase 1 — the box is tapped/opened: a crisp pickup pop.
  Future<void> boxTap() => _fx('box_tap.wav', 0.5);

  /// Rising shake ticks. [intensity] 0→1 lifts the volume and pitches the tick
  /// up so the tension audibly builds toward the break.
  Future<void> boxShakeTick(double intensity) {
    final i = intensity.clamp(0.0, 1.0);
    return _fx('box_tick.wav', 0.16 + 0.24 * i, rate: 1.0 + 0.6 * i);
  }

  /// The warm glow igniting inside the shell — a sustained riser on its own
  /// channel so it swells under the burst.
  Future<void> boxIgnite() async {
    if (!enabled) return;
    try {
      await _riser.stop();
      await _riser.play(AssetSource('sfx/box_ignite.wav'),
          volume: 0.5, mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  /// Phase 2 — the seal cracks: a low impact + sparkle.
  Future<void> boxBurst() => _fx('box_burst.wav', 0.72);

  /// Phase 4 — the reward lands: a level-up jingle ([grand] for legendary).
  Future<void> boxReveal({bool grand = false}) =>
      _fx(grand ? 'box_reveal_grand.wav' : 'box_reveal.wav', 0.72);

  /// The Collect tap — a satisfying coin chime.
  Future<void> boxCollect() => _fx('box_collect.wav', 0.6);

  // ── Avatar celebration (lesson-clear stage) ─────────────────────────────
  /// Linearly ramp the music volume to [to] over [dur]; optionally stop the
  /// player when it reaches silence.
  void _rampMusic(double to, Duration dur, {bool stopAtEnd = false}) {
    _musicFade?.cancel();
    final from = _musicVol;
    final start = DateTime.now();
    _musicFade = Timer.periodic(const Duration(milliseconds: 40), (tm) {
      final f = dur.inMilliseconds == 0
          ? 1.0
          : (DateTime.now().difference(start).inMilliseconds /
                  dur.inMilliseconds)
              .clamp(0.0, 1.0);
      _musicVol = from + (to - from) * f;
      _music.setVolume(_musicVol);
      if (f >= 1.0) {
        tm.cancel();
        if (stopAtEnd) _music.stop();
      }
    });
  }

  /// Start the looping Afrobeat groove, fading in from silence. Safe to call on
  /// screen mount; respects the global [enabled] mute.
  Future<void> startCelebrationLoop({double volume = 0.45}) async {
    if (!enabled) return;
    try {
      _musicFade?.cancel();
      _musicVol = 0.0;
      await _music.stop();
      await _music.play(AssetSource('sfx/highlife_loop.wav'), volume: 0.0);
      _rampMusic(volume, const Duration(milliseconds: 650));
    } catch (_) {}
  }

  /// Fade the groove out and stop it (call from the celebration screen's
  /// dispose — the singleton keeps the fade running after the widget is gone).
  Future<void> stopCelebrationLoop(
      {Duration fade = const Duration(milliseconds: 450)}) async {
    _rampMusic(0.0, fade, stopAtEnd: true);
  }

  /// Entrance flourish as the celebration stage blooms in.
  Future<void> celebrationFanfare() => _fx('celebrate_fanfare.wav', 0.7);

  /// A bright pop for each star / reward badge landing.
  Future<void> starPop() => _fx('celebrate_pop.wav', 0.55);
}
