import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'audio_bundle.dart';
import 'audio_cache.dart';

/// Speaks Twi text aloud. Resolution order (cheapest first):
///   1. A pre-generated clip bundled in the app  → zero API calls.
///   2. An in-memory cached clip from this session → zero API calls.
///   3. Live Khaya TTS via the backend            → uses API quota.
/// Lesson vocabulary should be covered by (1), so it never costs quota.
class TwiSpeech {
  TwiSpeech._();
  static final TwiSpeech instance = TwiSpeech._();

  final AudioPlayer _player = AudioPlayer();

  /// Whole-word pronunciation overrides for TTS — words the engine says wrong.
  /// The value is a phonetic respelling fed to the synth (audio only; display
  /// spelling is untouched).
  static const Map<String, String> _sayAs = {
    'fie': 'fi-e', // house/home — two syllables (fee-eh), not "fye"
  };

  /// Returns true if audio played, false if it could not be fetched.
  Future<bool> speak(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) return false;
    final t = _sayAs[raw.toLowerCase()] ?? raw;

    // 1) Bundled clip (free).
    final asset = await AudioBundle.instance.assetPathFor(t);
    if (asset != null) {
      try {
        await _player.stop();
        await _player.play(AssetSource(asset));
        return true;
      } catch (_) {/* fall through to cache/live */}
    }

    // 2) Cached clip → play for free, no API call.
    final key = TtsCache.instance.key(t);
    final cached = TtsCache.instance.get(key);
    if (cached != null) {
      try {
        await _player.stop();
        await _player.play(BytesSource(cached));
        return true;
      } catch (_) {
        return false;
      }
    }

    try {
      final res = await http.post(
        Uri.parse('$kBackendBaseUrl/api/tts'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': t, 'lang': 'tw'}),
      );
      if (res.statusCode != 200) return false;
      TtsCache.instance.put(key, res.bodyBytes);
      await _player.stop();
      await _player.play(BytesSource(res.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
  }
}
