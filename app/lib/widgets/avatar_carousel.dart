import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../theme.dart';
import 'avatar_badge.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

/// A horizontal avatar carousel: the centred avatar scales up (spring page
/// physics), the sides recede and dim. Tap a side avatar to glide to it; tap the
/// centred one to equip it (if unlocked). Locked avatars show a lock + their
/// unlock requirement.
class AvatarCarousel extends StatefulWidget {
  final String selectedId;
  final Set<String> unlockedIds;
  final ValueChanged<Avatar> onSelect;

  const AvatarCarousel({
    super.key,
    required this.selectedId,
    required this.unlockedIds,
    required this.onSelect,
  });

  @override
  State<AvatarCarousel> createState() => _AvatarCarouselState();
}

class _AvatarCarouselState extends State<AvatarCarousel> {
  late final PageController _pc;
  late double _page;

  int get _startIndex {
    final i = kAvatars.indexWhere((a) => a.id == widget.selectedId);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _page = _startIndex.toDouble();
    _pc = PageController(initialPage: _startIndex, viewportFraction: 0.5)
      ..addListener(() {
        if (mounted) setState(() => _page = _pc.page ?? _page);
      });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _tapItem(int i, bool locked) {
    if (i != _page.round()) {
      _pc.animateToPage(i,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack); // springy glide
    } else if (!locked) {
      HapticFeedback.selectionClick();
      widget.onSelect(kAvatars[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centre = kAvatars[_page.round().clamp(0, kAvatars.length - 1)];
    final centreLocked = !widget.unlockedIds.contains(centre.id);
    final isEquipped = centre.id == widget.selectedId && !centreLocked;

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _pc,
            itemCount: kAvatars.length,
            onPageChanged: (_) => HapticFeedback.selectionClick(),
            itemBuilder: (context, i) {
              final a = kAvatars[i];
              final locked = !widget.unlockedIds.contains(a.id);
              final dist = (i - _page).abs().clamp(0.0, 1.0);
              return Center(
                child: Opacity(
                  opacity: 1.0 - 0.5 * dist,
                  child: Transform.scale(
                    scale: 1.0 - 0.28 * dist,
                    child: TappableScale(
                      onTap: () => _tapItem(i, locked),
                      child: AvatarBadge(
                        avatar: a,
                        size: 112,
                        selected: a.id == widget.selectedId && !locked,
                        locked: locked,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(centre.name,
            style: displayFont(
                fontSize: 22, fontWeight: FontWeight.w700, color: kVelvetInk)),
        const SizedBox(height: 3),
        Text(
          centreLocked ? centre.unlockCriteria : centre.title.toUpperCase(),
          style: microLabel(color: centreLocked ? kOchre : kVelvetMuted),
        ),
        const SizedBox(height: 12),
        _StatusPill(
          locked: centreLocked,
          equipped: isEquipped,
          accent: centre.accent,
          onTap: centreLocked ? null : () => widget.onSelect(centre),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool locked;
  final bool equipped;
  final Color accent;
  final VoidCallback? onTap;
  const _StatusPill({
    required this.locked,
    required this.equipped,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color fg, bg, border;
    if (locked) {
      label = 'LOCKED';
      fg = kVelvetMuted;
      bg = Colors.transparent;
      border = Colors.white24;
    } else if (equipped) {
      label = 'EQUIPPED';
      fg = kOchre;
      bg = Colors.transparent;
      border = kOchre;
    } else {
      label = 'SELECT';
      fg = Colors.white;
      bg = terracottaDeep;
      border = terracottaDeep;
    }
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(label,
          style: displayFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 1.4)),
    );
    return onTap == null
        ? pill
        : TappableScale(onTap: onTap, child: pill);
  }
}
