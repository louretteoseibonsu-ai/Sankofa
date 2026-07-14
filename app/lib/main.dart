import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'auth_gate.dart';
import 'config.dart';
import 'services/currency_service.dart';
import 'theme.dart';

/// Pings the backend on launch so Render's free-tier server starts waking up
/// immediately (it sleeps after ~15 min idle). By the time the user reaches a
/// lesson's audio, it's more likely to be warm. Fire-and-forget; ignore errors.
void _warmBackend() async {
  try {
    await http
        .get(Uri.parse(kBackendBaseUrl))
        .timeout(const Duration(seconds: 30));
  } catch (_) {/* server still waking — that's fine */}
}

/// If Firebase fails to start, we stash the message here and show it on screen
/// instead of a blank page — so the cause is visible on a test device.
String? gStartupError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // On Android, Firebase reads android/app/google-services.json via the
    // google-services Gradle plugin. Timeout so a hung call can't freeze launch.
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    // Offline-first: cache the user doc + progress so the HUD renders instantly
    // from disk and syncs in the background (keeps streaks/leagues snappy and
    // usable with no connection).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e, s) {
    gStartupError = e.toString();
    debugPrint('Firebase init failed (continuing anyway): $e\n$s');
  }
  // Localise displayed prices from the user's region (non-blocking).
  CurrencyService.instance.ensureLoaded();
  // Start waking the audio/translation backend right away (non-blocking).
  _warmBackend();
  runApp(const SankofaTwiApp());
}

class SankofaTwiApp extends StatelessWidget {
  const SankofaTwiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sankofa Twi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: gStartupError == null
          ? const AuthGate()
          : _StartupErrorScreen(message: gStartupError!),
    );
  }
}

/// Shown only when Firebase failed to start — displays the reason.
class _StartupErrorScreen extends StatelessWidget {
  final String message;
  const _StartupErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Startup problem',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                  'The app could not start its services. Please screenshot this '
                  'and send it to support.',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EAE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(message,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9B2D2A))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
