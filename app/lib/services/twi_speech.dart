import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Speaks Twi text aloud using the backend Khaya TTS endpoint.
class TwiSpeech {
  TwiSpeech._();
  static final TwiSpeech instance = TwiSpeech._();

  final AudioPlayer _player = AudioPlayer();

  /// Returns true if audio played, false if it could not be fetched.
  Future<bool> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$kBackendBaseUrl/api/tts'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': t, 'lang': 'tw'}),
      );
      if (res.statusCode != 200) return false;
      await _player.stop();
      await _player.play(BytesSource(res.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
  }
}
