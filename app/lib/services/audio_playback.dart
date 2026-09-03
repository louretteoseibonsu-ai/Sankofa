import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// iOS-safe audio helpers.
///
/// Two iOS gotchas this fixes (both work fine on Android without it):
///  1. iOS stays silent unless the audio session category is "playback" — set
///     it once at startup so audio plays even with the ring/silent switch on.
///  2. iOS can't reliably play from `BytesSource` (raw bytes). Fetched TTS must
///     be written to a temp file and played via `DeviceFileSource` instead.

/// Call once at app startup (before any playback).
Future<void> setupGlobalAudioContext() async {
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  } catch (_) {/* non-fatal — playback still attempted below */}
}

// Rotate through a few temp filenames so a rapid re-tap doesn't overwrite a
// file that's still being read by the player.
int _seq = 0;

/// Reliably plays raw audio bytes on both platforms by writing them to a temp
/// file first (iOS can't play `BytesSource`). Throws on failure so callers can
/// fall back / surface an error, mirroring the previous behaviour.
Future<void> playBytes(AudioPlayer player, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  _seq = (_seq + 1) % 8;
  final file = File('${dir.path}/tts_$_seq.wav');
  await file.writeAsBytes(bytes, flush: true);
  await player.stop();
  await player.play(DeviceFileSource(file.path));
}
