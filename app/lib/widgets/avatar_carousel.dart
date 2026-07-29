import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../theme.dart';
import 'avatar_badge.dart';
import 'kente_shard.dart';
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

  /// Current shard balance + a callback to buy a locked member early. When both
  /// are provided, a locked avatar shows an "Unlock · N" shard button.
  final int shards;
  final ValueChanged<Avatar>? onUnlock;

  const AvatarCarousel({
    super.key,
    required this.selectedId,
    required this.unlockedIds,
    required this.onSelect,
    this.shards = 0,
    this.onUnlock,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Per-character colour bloom behind the focused avatar.
                        IgnorePointer(
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  a.accent.withValues(
                                      alpha: (locked ? 0.14 : 0.45) *
                                          (1 - dist)),
                                  Colors.transparent,
                                ],
                                stops: const [0.15, 1.0],
                              ),
                            ),
                          ),
                        ),
                        TappableScale(
                          onTap: () => _tapItem(i, locked),
                          child: AvatarBadge(
                            avatar: a,
                            size: 112,
                            selected: a.id == widget.selectedId && !locked,
                            locked: locked,
                          ),
                        ),
                      ],
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
        if (!centreLocked)
          _StatusPill(
            locked: false,
            equipped: isEquipped,
            accent: centre.accent,
            onTap: () => widget.onSelect(centre),
          )
        else if (widget.onUnlock != null && centre.shardCost > 0)
          _UnlockPill(
            cost: centre.shardCost,
            affordable: widget.shards >= centre.shardCost,
            onUnlock: () => widget.onUnlock!(centre),
          )
        else
          const _StatusPill(locked: true, equipped: false, accent: kOchre),
      ],
    );
  }
}

/// Locked-avatar action: buy the family member early with shards. Reads active
/// (terracotta) when affordable, dimmed otherwise — the parent shows a message
/// if there aren't enough shards.
class _UnlockPill extends StatelessWidget {
  final int cost;
  final bool affordable;
  final VoidCallback onUnlock;
  const _UnlockPill({
    required this.cost,
    required this.affordable,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return TappableScale(
      onTap: onUnlock,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: affordable
              ? const LinearGradient(
                  colors: [Color(0xFFE07A3E), Color(0xFFE3A92C)])
              : null,
          color: affordable ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: affordable
              ? null
              : Border.all(color: Colors.white24, width: 1.5),
          boxShadow: affordable
              ? [
                  BoxShadow(
                      color: const Color(0xFFE3A92C).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(affordable ? 'UNLOCK · $cost' : 'NEED $cost',
                style: displayFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: affordable ? const Color(0xFF1A1206) : kVelvetMuted,
                    letterSpacing: 1.2)),
            const SizedBox(width: 6),
            KenteShard(size: 15, muted: !affordable),
          ],
        ),
      ),
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
    List<BoxShadow>? glow;
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
      // SELECT — filled in the character's own accent, with a matching glow.
      label = 'SELECT';
      fg = const Color(0xFF1A1206);
      bg = accent;
      border = accent;
      glow = [
        BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 5)),
      ];
    }
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
        boxShadow: glow,
      ),
      child: Text(label,
          style: displayFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 1.4)),
    );
    return onTap == null
        ? pill
        : TappableScale(onTap: onTap, child: pill);
  }
}
