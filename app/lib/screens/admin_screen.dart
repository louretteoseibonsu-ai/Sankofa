import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

/// Team-facing admin panel to manage sign-ups. Reachable from Profile only
/// when the signed-in user is in admins/{uid}.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _admin = AdminService();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AdminUser> _filter(List<AdminUser> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
            (u.email ?? '').toLowerCase().contains(q) ||
            (u.name ?? '').toLowerCase().contains(q) ||
            u.uid.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),

      appBar: AppBar(title: const Text('Admin · Sign-ups')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by email, name, or ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdminUser>>(
              stream: _admin.usersStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const _Message(
                    icon: Icons.lock_outline,
                    title: 'Access denied',
                    body:
                        'Your account is not an admin, or the Firestore rules '
                        'have not been deployed yet.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = _filter(snap.data!);
                if (users.isEmpty) {
                  return _Message(
                    icon: Icons.people_outline,
                    title: _query.isEmpty ? 'No sign-ups yet' : 'No matches',
                    body: _query.isEmpty
                        ? 'New accounts will appear here as people sign up.'
                        : 'Try a different search.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: users.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                        child: Text(
                          '${snap.data!.length} total · '
                          '${snap.data!.where((u) => u.premium).length} premium · '
                          '${snap.data!.where((u) => u.disabled).length} suspended',
                          style: const TextStyle(color: kVelvetMuted, fontSize: 12),
                        ),
                      );
                    }
                    return _UserTile(
                      user: users[i - 1],
                      admin: _admin,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final AdminService admin;
  const _UserTile({required this.user, required this.admin});

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _confirmDelete(
      BuildContext context, ScaffoldMessengerState messenger) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account?'),
        content: Text(
            'This permanently deletes ${user.label}\'s login and all their '
            'data — progress, streaks, and pedis. This cannot be undone.\n\n'
            'To temporarily block access instead, use Suspend.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9B2D2A)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete forever')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await admin.deleteUser(user.uid);
      messenger.showSnackBar(
          SnackBar(content: Text('Deleted ${user.label}')));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? 'Delete failed.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Delete failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.disabled ? const Color(0xFF9B2D2A) : Colors.white10,
          width: user.disabled ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: kVelvetInk)),
                      if (user.email != null && user.email != user.label)
                        Text(user.email!,
                            style:
                                const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                      Text(
                          'Joined ${_fmt(user.createdAt)} · '
                          '${user.pedis} pedis · ${user.xp} XP',
                          style: const TextStyle(color: kVelvetMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
                if (user.premium)
                  const _Chip(label: 'Premium', color: Color(0xFFE3A92C)),
                if (user.disabled)
                  const _Chip(label: 'Suspended', color: Color(0xFF9B2D2A)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  icon: Icon(
                      user.premium ? Icons.star : Icons.star_border,
                      size: 18),
                  label: Text(user.premium ? 'Remove premium' : 'Make premium'),
                  onPressed: () async {
                    await admin.setPremium(user.uid, !user.premium);
                    messenger.showSnackBar(SnackBar(
                        content: Text(user.premium
                            ? 'Premium removed'
                            : 'Premium granted')));
                  },
                ),
                TextButton.icon(
                  icon: Icon(
                      user.disabled ? Icons.lock_open : Icons.block,
                      size: 18,
                      color: const Color(0xFF9B2D2A)),
                  label: Text(user.disabled ? 'Restore' : 'Suspend',
                      style: const TextStyle(color: Color(0xFF9B2D2A))),
                  onPressed: () async {
                    await admin.setDisabled(user.uid, !user.disabled);
                    messenger.showSnackBar(SnackBar(
                        content: Text(user.disabled
                            ? 'Account restored'
                            : 'Account suspended')));
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('+50 pedis'),
                  onPressed: () async {
                    await admin.addPedis(user.uid, 50);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Granted 50 pedis')));
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever,
                      size: 18, color: Color(0xFF9B2D2A)),
                  label: const Text('Delete',
                      style: TextStyle(color: Color(0xFF9B2D2A))),
                  onPressed: () => _confirmDelete(context, messenger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Message(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: kVelvetMuted),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18, color: kVelvetInk)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kVelvetMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
