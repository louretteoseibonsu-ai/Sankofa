import 'package:flutter/material.dart';
import '../theme.dart';
import 'kente_shard.dart';
import 'surface.dart';

/// Juicy currency-gain feedback: a "+N ◈" chip that pops in, floats upward and
/// fades out over the current screen. Fire it whenever the player earns shards.
///
/// ```dart
/// ShardGain.show(context, 30);                 // centred
/// ShardGain.show(context, 5, at: tapOffset);   // from a point (global coords)
/// ```
class ShardGain {
  const ShardGain._();

  static void show(BuildContext context, int amount, {Offset? at}) {
    if (amount <= 0) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FloatingShard(
        amount: amount,
        at: at,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FloatingShard extends StatefulWidget {
  final int amount;
  final Offset? at;
  final VoidCallback onDone;
  const _FloatingShard({
    required this.amount,
    required this.at,
    required this.onDone,
  });

  @override
  State<_FloatingShard> createState() => _FloatingShardState();
}

class _FloatingShardState extends State<_FloatingShard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = _c.value;
        // Elastic pop-in over the first quarter, then rise + fade.
        final pop =
            p < 0.25 ? Curves.elasticOut.transform((p / 0.25).clamp(0, 1)) : 1.0;
        final rise = Curves.easeOut.transform(p) * 64.0;
        final fade = p < 0.65 ? 1.0 : (1 - (p - 0.65) / 0.35).clamp(0.0, 1.0);

        final chip = Transform.translate(
          offset: Offset(0, -rise),
          child: Opacity(
            opacity: fade,
            child: Transform.scale(scale: pop, child: _chip()),
          ),
        );

        // Anchor at a global point if given, else centre.
        if (widget.at != null) {
          return Positioned(
            left: widget.at!.dx - 40,
            top: widget.at!.dy - 20,
            child: IgnorePointer(child: chip),
          );
        }
        return Positioned.fill(
          child: IgnorePointer(child: Center(child: chip)),
        );
      },
    );
  }

  Widget _chip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kAmbientShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KenteShard(size: 18),
            const SizedBox(width: 5),
            Text('+${widget.amount}',
                style: displayFont(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: terracottaDeep)),
          ],
        ),
      );
}
