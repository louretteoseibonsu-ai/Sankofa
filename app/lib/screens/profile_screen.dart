import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../data/adinkra_symbols.dart';
import '../data/akan_day_names.dart';
import '../data/special_avatars.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/floating_card.dart';
import '../widgets/pedis_store.dart';
import '../widgets/velvet.dart';
import 'admin_screen.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;
import 'help_screen.dart';
import 'invite_friends_screen.dart';
import 'legal_screen.dart';
import 'symbols_screen.dart' show kFreeSymbols;
import 'upgrade_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _AvatarMode { adinkra, photo }

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  late final TextEditingController _name;

  // accent colors offered for Adinkra avatars
  static const _colors = ['E2725B', '2B2B2D', '5A5E63', 'E3A92C', '9B2D2A', '2E6B3B'];

  // Inclusive gender options.
  static const _genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Genderfluid',
    'Agender',
    'Prefer to self-describe',
    'Prefer not to say',
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  _AvatarMode _mode = _AvatarMode.adinkra;
  String _glyph = 'gyenyame';
  String _hex = 'E2725B';
  String? _existingPhoto;
  File? _picked;
  bool _loading = false;

  DateTime? _dob;
  String? _assignedDayName; // set when the user assigns their Akan day name
  String _gender = '';
  bool _premium = false;
  bool _isAdmin = false;
  int _pedis = 0;
  late final TextEditingController _selfDescribe;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _name = TextEditingController(
        text: u?.displayName ?? (u?.email?.split('@').first ?? ''));
    _selfDescribe = TextEditingController();
    final p = u?.photoURL;
    if (p != null && p.startsWith('adinkra://')) {
      final parts = p.substring('adinkra://'.length).split('/');
      _glyph = parts.isNotEmpty ? parts[0] : 'gyenyame';
      _hex = parts.length > 1 ? parts[1] : '2B2B2D';
      _mode = _AvatarMode.adinkra;
    } else if (p != null && p.startsWith('http')) {
      _existingPhoto = p;
      _mode = _AvatarMode.photo;
    }
    _loadExtended();
  }

  Future<void> _loadExtended() async {
    final p = await _auth.loadProfile();
    final admin = await _auth.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _pedis = (p['pedis'] as num?)?.toInt() ?? 0;
      _premium = (p['premium'] as bool?) ?? false;
      final dobStr = p['dob'] as String?;
      if (dobStr != null) _dob = DateTime.tryParse(dobStr);
      final g = p['gender'] as String?;
      if (g != null && g.isNotEmpty) {
        if (_genderOptions.contains(g)) {
          _gender = g;
        } else {
          _gender = 'Prefer to self-describe';
          _selfDescribe.text = g;
        }
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _selfDescribe.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Once a birth date is set, offer the matching Akan day name(s) to assign as
  /// the display name. Shows the male + female name until a gender is chosen.
  Widget _dayNameSuggestion() {
    final dob = _dob;
    if (dob == null) return const SizedBox.shrink();
    // Dart weekday Mon=1..Sun=7 → Akan table Sun=0..Sat=6.
    final day = kAkanDayNames[dob.weekday % 7];
    final names = _gender == 'Man'
        ? [day.maleName]
        : _gender == 'Woman'
            ? [day.femaleName]
            : [day.maleName, day.femaleName];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.auto_awesome, size: 16, color: terracotta),
            SizedBox(width: 6),
            Text('Your Akan day name',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kVelvetInk,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Text('Born on ${day.dayTwi} · ${day.attribute}',
              style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final n in names) _dayNameChip(n)],
          ),
        ],
      ),
    );
  }

  Widget _dayNameChip(String name) {
    final selected = _assignedDayName == name;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _assignedDayName = name;
          _name.text = name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day name "$name" set as your display name')),
        );
      },
      icon: Icon(selected ? Icons.check_circle : Icons.add, size: 16),
      label: Text('Use "$name"'),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Color get _color {
    final v = int.tryParse('FF$_hex', radix: 16) ?? 0xFF5A5E63;
    return Color(v);
  }

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker()
        .pickImage(source: src, maxWidth: 800, imageQuality: 85);
    if (x != null) {
      setState(() {
        _picked = File(x.path);
        _mode = _AvatarMode.photo;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      if (_name.text.trim().isNotEmpty) {
        await _auth.updateDisplayName(_name.text);
      }
      if (_mode == _AvatarMode.photo && _picked != null) {
        await _auth.uploadPhotoAvatar(_picked!);
      } else if (_mode == _AvatarMode.adinkra) {
        await _auth.setAdinkraAvatar(_glyph, _hex);
      }
      String? genderToSave;
      if (_gender == 'Prefer to self-describe') {
        final t = _selfDescribe.text.trim();
        genderToSave = t.isEmpty ? 'Prefer to self-describe' : t;
      } else if (_gender.isNotEmpty) {
        genderToSave = _gender;
      }
      final dobToSave = _dob == null
          ? null
          : '${_dob!.year.toString().padLeft(4, '0')}-'
              '${_dob!.month.toString().padLeft(2, '0')}-'
              '${_dob!.day.toString().padLeft(2, '0')}';
      if (genderToSave != null ||
          dobToSave != null ||
          _assignedDayName != null) {
        await _auth.saveProfile(
            dob: dobToSave, gender: genderToSave, dayName: _assignedDayName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved')));
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      debugPrint('Profile save/upload failed: $e\n$s');
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Could not save: ${msg.length > 140 ? '${msg.substring(0, 140)}…' : msg}'),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel subscription?'),
        content: const Text(
            'Subscriptions are managed by your app store. To cancel, open '
            'Play Store → Subscriptions (Android), or App Store → your name → '
            'Subscriptions (iPhone). Your Premium access stays active until the '
            'end of the paid period.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Premium')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9B2D2A)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel now')),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.setPremium(false); // placeholder until real billing
      if (!mounted) return;
      setState(() => _premium = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Premium cancelled. (Real cancellations process through your app store.)')));
    }
  }

  void _openUpgrade() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()))
      .then((_) => _loadExtended());

  Future<void> _openPedisStore() async {
    final bought = await showPedisStore(context, currentPedis: _pedis);
    if (bought > 0 && mounted) _loadExtended();
  }

  Future<void> _resendVerify() async {
    await _auth.resendVerification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verification email sent. Check your inbox.')));
    }
  }

  Future<void> _deleteAccount() async {
    final isPw = _auth.isPasswordUser;
    final pwCtrl = TextEditingController();
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'This permanently deletes your account and all your data — '
                  'progress, streaks, pedis, and profile. This cannot be undone.'),
              if (isPw) ...[
                const SizedBox(height: 14),
                const Text('Enter your password to confirm:',
                    style: TextStyle(fontSize: 12.5, color: kVelvetMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: pwCtrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Text("You'll be asked to confirm with Google.",
                    style: TextStyle(fontSize: 12.5, color: kVelvetMuted)),
              ],
            ],
          ),
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
      if (confirm != true) return;
      if (isPw && pwCtrl.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter your password to confirm.')));
        }
        return;
      }
      try {
        await _auth.deleteAccount(password: isPw ? pwCtrl.text : null);
        // AuthGate will swap to the login screen automatically on success.
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String msg;
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'password-required') {
          msg = 'Incorrect password. Please try again.';
        } else if (e.code == 'reauth-cancelled') {
          msg = 'Deletion cancelled.';
        } else if (e.code == 'requires-recent-login') {
          msg = 'Please sign out and back in, then try again.';
        } else {
          msg = e.message ?? 'Could not delete account.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not delete account. Please try again.')));
        }
      }
    } finally {
      pwCtrl.dispose();
    }
  }

  Widget _preview() {
    if (_mode == _AvatarMode.photo && _picked != null) {
      return CircleAvatar(radius: 48, backgroundImage: FileImage(_picked!));
    }
    if (_mode == _AvatarMode.photo && _existingPhoto != null) {
      return CircleAvatar(radius: 48, backgroundImage: NetworkImage(_existingPhoto!));
    }
    final svg = _glyph == kAnanseGlyphId
        ? kAnanseSvg
        : kAdinkraSymbols
            .firstWhere((s) => s.id == _glyph,
                orElse: () => kAdinkraSymbols.first)
            .svg;
    return CircleAvatar(
      radius: 48,
      backgroundColor: _color,
      child: SizedBox(
        width: 60,
        height: 60,
        child: SvgPicture.string(svg,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: _preview()),
          const SizedBox(height: 20),
          if (_auth.isPasswordUser && !_auth.isEmailVerified) ...[
            FloatingCard(
              child: Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined,
                      color: terracotta, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify your email',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: kVelvetInk)),
                        Text('We sent you a confirmation link.',
                            style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: _resendVerify, child: const Text('Resend')),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Display name',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: 22),
          const Text('Date of birth',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _dob == null ? 'Select your date of birth' : _formatDob(_dob!),
                style: TextStyle(
                  fontSize: 16,
                  color: _dob == null ? kVelvetMuted : kVelvetInk,
                ),
              ),
            ),
          ),
          _dayNameSuggestion(),
          const SizedBox(height: 22),
          const Text('Gender',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _gender.isEmpty ? null : _gender,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            hint: const Text('Select gender'),
            items: _genderOptions
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? ''),
          ),
          if (_gender == 'Prefer to self-describe') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _selfDescribe,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Describe your gender (optional)',
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Pick an Adinkra avatar',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kAdinkraSymbols.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = kAdinkraSymbols[i];
                final locked = !_premium && i >= kFreeSymbols;
                final selected = _mode == _AvatarMode.adinkra && s.id == _glyph;
                // Tint glyphs light so they read on the dark velvet tiles
                // (selection is shown by the terracotta tile border).
                final glyph = SvgPicture.string(s.svg,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                        kVelvetInk, BlendMode.srcIn));
                return GestureDetector(
                  onTap: locked
                      ? _openUpgrade
                      : () => setState(() {
                            _glyph = s.id;
                            _mode = _AvatarMode.adinkra;
                          }),
                  child: Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A211C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? terracotta : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    // Premium symbols are blurred + lock-badged until unlocked,
                    // matching the Symbols gallery teaser style.
                    child: locked
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImageFiltered(
                                  imageFilter:
                                      ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Opacity(opacity: 0.5, child: glyph),
                                ),
                              ),
                              const Positioned(
                                right: -6,
                                top: -6,
                                child: Icon(Icons.lock,
                                    size: 14, color: Color(0xFFE3A92C)),
                              ),
                            ],
                          )
                        : glyph,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Text('Accent color',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: _colors.map((h) {
              final v = int.tryParse('FF$h', radix: 16) ?? 0xFF5A5E63;
              final selected = _mode == _AvatarMode.adinkra && h == _hex;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _hex = h;
                    _mode = _AvatarMode.adinkra;
                  }),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(v),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? kVelvetInk : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const Text('…or use a photo',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save profile'),
          ),
          const SizedBox(height: 22),

          _ProfileGroup(
            title: 'Account & settings',
            children: [
              // ── Subscription ──
              const Text('Subscription',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          if (_premium)
            FloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('✦',
                          style: TextStyle(color: Color(0xFFE3A92C), fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Premium active',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: kVelvetInk)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                            onPressed: _openUpgrade,
                            child: const Text('Change plan')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelSubscription,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF9B2D2A)),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            FloatingCard(
              onTap: _openUpgrade,
              child: const Row(
                children: [
                  Text('✦',
                      style: TextStyle(color: Color(0xFFE3A92C), fontSize: 18)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upgrade to Premium',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: kVelvetInk)),
                        Text('7-day free trial · change plans anytime',
                            style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white30),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // ── Pedis wallet ──
          const Text('Pedis',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: _openPedisStore,
            child: Row(
              children: [
                const Icon(Icons.spa, color: plantainGreen, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_pedis pedis',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: kVelvetInk)),
                      const Text(
                          'Top up Translate & Lens credits, freezes, avatars',
                          style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _openPedisStore,
                  child: const Text('Get pedis'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Invite friends ──
          const Text('Invite friends',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const InviteFriendsScreen())),
            child: const Row(
              children: [
                Icon(Icons.group_add_outlined,
                    color: terracotta, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite friends & earn pedis',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: kVelvetInk)),
                      Text(
                          'You both get $kInviteRewardPedis pedis · learn '
                          'together on a friends leaderboard',
                          style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Admin (team only) ──
          if (_isAdmin) ...[
            const Text('Team',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            FloatingCard(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminScreen())),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      size: 20, color: kVelvetInk),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin panel',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: kVelvetInk)),
                        Text('Manage sign-ups, premium & suspensions',
                            style: TextStyle(color: kVelvetMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white30),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Help & support ──
          const Text('Help & support',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen())),
            child: const Row(
              children: [
                Icon(Icons.help_outline, size: 20, color: kVelvetInk),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Help center & support chat',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: kVelvetInk)),
                      Text('FAQs, AI chat, and sankofa@aparato.ai',
                          style: TextStyle(color: kVelvetMuted, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Legal ──
          const Text('Legal',
              style: TextStyle(
                  color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LegalScreen(
                    title: 'Privacy Policy', body: kPrivacyPolicy))),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 20, color: kVelvetInk),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LegalScreen(
                    title: 'Terms & Conditions', body: kTermsAndConditions))),
            child: const Row(
              children: [
                Icon(Icons.description_outlined, size: 20, color: kVelvetInk),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Terms & Conditions',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
            ],
          ),
          const SizedBox(height: 16),
          FloatingCard(
            onTap: () async {
              await _auth.signOut();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Row(
              children: [
                Icon(Icons.logout, size: 18, color: kVelvetInk),
                SizedBox(width: 10),
                Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FloatingCard(
            onTap: _deleteAccount,
            child: const Row(
              children: [
                Icon(Icons.delete_forever, size: 18, color: Color(0xFF9B2D2A)),
                SizedBox(width: 10),
                Text('Delete account',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFF9B2D2A))),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }
}

/// A collapsible group so the profile's account/settings tail stays tidy.
class _ProfileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ProfileGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface)),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        children: children,
      ),
    );
  }
}

/// The Anansesɛm reveal + premium gate. Pops `true` if the user subscribes.
