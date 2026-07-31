import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

/// AI support chat — answers from the Sankofa Twi knowledge base via the
/// backend /api/support endpoint (Gemini, grounded + with a human-handoff rule).
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _Msg {
  final bool fromUser;
  final String text;
  _Msg(this.fromUser, this.text);
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    _Msg(false,
        'Akwaaba! 🌿 I\'m the Sankofa Twi support assistant. Ask me anything — '
        'lessons, audio, Premium, your account… How can I help?'),
  ];
  List<dynamic> _history = []; // opaque Gemini history, round-tripped
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg(true, text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final res = await http
          .post(
            Uri.parse('$kBackendBaseUrl/api/support'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text, 'history': _history}),
          )
          .timeout(const Duration(seconds: 40));
      if (res.statusCode != 200) throw Exception('support ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final reply = (data['reply'] ?? '').toString().trim();
      setState(() {
        _history = (data['history'] as List?) ?? _history;
        _messages.add(_Msg(
            false,
            reply.isEmpty
                ? 'Sorry, I didn\'t catch that. Could you rephrase? If it\'s '
                    'urgent, email sankofa@aparato.ai.'
                : reply));
      });
    } catch (_) {
      setState(() {
        _messages.add(_Msg(false,
            'I\'m having trouble connecting right now. Please try again, or '
            'email our team at sankofa@aparato.ai.'));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),

      appBar: AppBar(title: const Text('Support chat')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return const _TypingBubble();
                  return _Bubble(msg: _messages[i]);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type your question…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14)),
                    child: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final user = msg.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: user ? terracottaDeep : Color(0xFF2A211C),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(
                color: user ? Colors.white : kVelvetInk, height: 1.4, fontSize: 14.5)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Color(0xFF2A211C), borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
