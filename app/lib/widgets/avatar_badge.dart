import 'package:flutter/material.dart';
import '../data/avatar.dart';
import '../theme.dart';
import 'surface.dart';
import 'velvet.dart';

/// A circular avatar badge. Renders the real portrait once its art is bundled;
/// until then a sculpted placeholder (radial gradient in the avatar's accent +
/// Space Grotesk monogram). Multi-layer ambient shadow gives physical presence;
/// [locked] dims it and stamps a lock.
class AvatarBadge extends StatelessWidget {
  final Avatar avatar;
  final double size;
  final bool selected;
  final bool locked;

  const AvatarBadge({
    super.key,
    required this.avatar,
    this.size = 96,
    this.selected = false,
    this.locked = false,
  });

  static Future<bool> _hasArt(BuildContext c, String path) async {
    try {
      await DefaultAssetBundle.of(c).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ring = selected ? kOchre : Colors.white24;
    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: selected ? 3 : 2),
        boxShadow: kAmbientShadow,
      ),
      child: ClipOval(
        child: FutureBuilder<bool>(
          future: _hasArt(context, avatar.assetReference),
          builder: (context, snap) => snap.data == true
              ? Image.asset(avatar.assetReference,
                  width: size, height: size, fit: BoxFit.cover)
              : _placeholder(),
        ),
      ),
    );

    if (locked) {
      badge = Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
                Color(0xB3141210), BlendMode.srcATop),
            child: badge,
          ),
          Icon(Icons.lock_rounded,
              color: Colors.white.withValues(alpha: 0.85), size: size * 0.30),
        ],
      );
    }
    return badge;
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.35),
          radius: 1.1,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.22), avatar.accent),
            avatar.accent,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.38), avatar.accent),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          avatar.initials,
          style: displayFont(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }
}
