import 'package:flutter/material.dart';
import '../data/landmark.dart';
import '../theme.dart';
import 'velvet.dart';

/// Opens the landmark info panel — a velvet-dark bottom sheet that slides + eases
/// in on a custom curve, showing the landmark's image, name and description in
/// the displayFont hierarchy.
void showLandmarkSheet(BuildContext context, Landmark lm) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (_) => _LandmarkSheet(lm),
  );
}

class _LandmarkSheet extends StatelessWidget {
  final Landmark lm;
  const _LandmarkSheet(this.lm);

  static Future<bool> _hasArt(BuildContext c, String path) async {
    try {
      await DefaultAssetBundle.of(c).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  IconData get _icon {
    switch (lm.id) {
      case 'kakum':
        return Icons.forest_rounded;
      case 'osu':
        return Icons.storefront_rounded;
      case 'coco':
      case 'labadi':
        return Icons.beach_access_rounded;
      case 'elmina':
        return Icons.account_balance_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom curved entrance on top of the sheet's own slide.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t) * 44), child: child),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kVelvetTop, kVelvetBottom],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              // Hero image (or sculpted placeholder in the landmark accent).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: FutureBuilder<bool>(
                      future: _hasArt(context, lm.imageAsset),
                      builder: (context, snap) => snap.data == true
                          ? Image.asset(lm.imageAsset, fit: BoxFit.cover)
                          : _placeholder(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_rounded, size: 13, color: kOchre),
                        const SizedBox(width: 5),
                        Text(lm.region.toUpperCase(),
                            style: microLabel(color: kOchre)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(lm.name,
                        style: displayFont(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: kVelvetInk,
                            height: 1.05)),
                    if (!lm.isUnlocked) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded,
                              size: 14, color: kVelvetMuted),
                          const SizedBox(width: 6),
                          Text('Keep travelling to unlock this stop',
                              style: TextStyle(
                                  color: kVelvetMuted,
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(lm.descriptionText,
                        style: const TextStyle(
                            color: Color(0xFFCFC6BD),
                            fontSize: 14.5,
                            height: 1.62)),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.10), lm.accent),
            Color.alphaBlend(Colors.black.withValues(alpha: 0.35), lm.accent),
          ],
        ),
      ),
      child: Center(
        child: Icon(_icon, size: 66, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}
