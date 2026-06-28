import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/floating_card.dart';
import '../widgets/premium_lock.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _controller = TextEditingController();
  final _player = AudioPlayer();
  bool _enToTw = true; // direction
  bool _loading = false;
  String? _translation;
  String? _error;
  bool? _premium; // null = checking

  @override
  void initState() {
    super.initState();
    AuthService().isPremium().then((v) {
      if (mounted) setState(() => _premium = v);
    });
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
    }
  }

  Future<void> _listen() async {
    final t = _translation;
    if (t == null || t.isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse('$kBackendBaseUrl/api/tts'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': t, 'lang': 'tw'}),
      );
      if (res.statusCode != 200) throw Exception('tts ${res.statusCode}');
      await _player.play(BytesSource(res.bodyBytes));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not play Twi audio.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_premium == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_premium == false) {
      return const PremiumLock(
        title: 'AI Translate is a Premium tool',
        message:
            'Unlock unlimited English ⇆ Twi translation with native Twi audio, '
            'plus every lesson, symbol, and more.',
        icon: Icons.translate,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Deep Translation',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: ink)),
        const SizedBox(height: 18),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('English → Twi')),
            ButtonSegment(value: false, label: Text('Twi → English')),
          ],
          selected: {_enToTw},
          onSelectionChanged: (s) => setState(() => _enToTw = s.first),
        ),
        const SizedBox(height: 16),
        FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _enToTw ? 'Type English…' : 'Type Twi…',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
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
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Translation',
                    style: TextStyle(
                        color: plantainGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text(_translation!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20, color: ink)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _listen,
                  icon: const Icon(Icons.volume_up, color: plantainGreen),
                  label: const Text('Listen (Twi)'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
