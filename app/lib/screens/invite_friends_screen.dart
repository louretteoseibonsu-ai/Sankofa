import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../config.dart';
import '../services/friends_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;
import '../widgets/floating_card.dart';

/// Invite & Earn + Learn with friends: share your code, redeem a friend's code
/// (both earn pedis), and see a friends-only leaderboard.
class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final _friends = FriendsService();
  final _redeem = TextEditingController();
  String? _code;
  bool _redeeming = false;
  Future<List<FriendRank>>? _board;

  @override
  void initState() {
    super.initState();
    _load();
    _board = _friends.friendsLeaderboard();
  }

  Future<void> _load() async {
    try {
      final c = await _friends.inviteCode();
      if (mounted) setState(() => _code = c);
    } catch (_) {
      if (mounted) setState(() => _code = '—');
    }
  }

  @override
  void dispose() {
    _redeem.dispose();
    super.dispose();
  }

  String get _inviteMessage =>
      'Learn Twi with me on Sankofa Twi! 🌿 Use my code ${_code ?? ''} when you '
      'sign up and we both get $kInviteRewardPedis pedis. Akwaaba!';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _inviteMessage));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invite copied — paste it to a friend!')));
    }
  }

  Future<void> _doRedeem() async {
    final code = _redeem.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    try {
      final reward = await _friends.redeem(code);
      if (!mounted) return;
      _redeem.clear();
      setState(() => _board = _friends.friendsLeaderboard());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: charcoal,
          duration: const Duration(seconds: 5),
          content: Text('🎉 Invite accepted! Finish your first lesson and you '
              'both get $reward pedis.')));
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'That code did not work.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not redeem right now. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),

      appBar: AppBar(title: const Text('Invite friends')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Reward hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3A92C), width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎁 Learn together, earn together',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  SizedBox(height: 6),
                  Text(
                      'You and your friend each get $kInviteRewardPedis pedis '
                      'once they join with your code and finish their first '
                      'lesson.',
                      style: TextStyle(
                          color: Color(0xFFC9CCD1), height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Your code
            const Text('Your invite code',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            FloatingCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _code ?? 'Loading…',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: 3,
                          color: kVelvetInk),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: (_code == null || _code == '—') ? null : _copy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy invite'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Redeem
            const Text('Have a friend\'s code?',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            FloatingCard(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _redeem,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter code',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _redeeming ? null : _doRedeem,
                    child: _redeeming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Redeem'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Friends leaderboard
            const Text('Learn with friends',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
            const SizedBox(height: 4),
            const Text('You and the friends you invite, ranked by XP.',
                style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
            const SizedBox(height: 12),
            FutureBuilder<List<FriendRank>>(
              future: _board,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rows = snap.data ?? const [];
                if (rows.length <= 1) {
                  return const Text(
                      'Invite a friend to start your private leaderboard!',
                      style: TextStyle(color: kVelvetMuted));
                }
                return Column(
                  children: [
                    for (int i = 0; i < rows.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FloatingCard(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: kVelvetMuted)),
                              ),
                              Expanded(
                                child: Text(
                                    rows[i].isMe
                                        ? '${rows[i].name} (you)'
                                        : rows[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: rows[i].isMe
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: rows[i].isMe ? terracotta : kVelvetInk)),
                              ),
                              Text('${rows[i].xp} XP',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: kVelvetInk)),
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
    ));
  }
}
