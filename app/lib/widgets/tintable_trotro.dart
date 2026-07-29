import 'package:flutter/material.dart';

/// The Compound body-paint palette. Index 0 is the default terracotta. Stored as
/// an index (not a raw ARGB) so persistence stays SDK-agnostic.
const List<Color> kTroTroBodyColors = [
  Color(0xFFE8551F), // terracotta (default)
  Color(0xFF2E6FC7), // sky blue
  Color(0xFF2E9E5B), // green
  Color(0xFF8A57C2), // purple
  Color(0xFFCB4242), // red
  Color(0xFF1FA99A), // teal
  Color(0xFFE3A92C), // gold
  Color(0xFFD46A97), // pink
];

/// The equipped body colour from the cosmetics map (defaults to terracotta).
Color troTroBodyColorFor(Map<String, String> equipped) =>
    kTroTroBodyColors[troTroBodyIndexFor(equipped)];

/// The equipped body-colour index (clamped to the palette; defaults to 0).
int troTroBodyIndexFor(Map<String, String> equipped) {
  final i = int.tryParse(equipped['bodyColor'] ?? '');
  return (i != null && i >= 0 && i < kTroTroBodyColors.length) ? i : 0;
}

/// The illustrated tro tro, built as a stack of transparent layers so it is both
/// recolourable AND moddable at runtime. Stacking order (bottom → top):
///
///   1. mask.png    — masked paintwork, tinted live via `ColorFiltered`
///                    (`BlendMode.modulate`) so [bodyColor] keeps its shading.
///   2. rim/<id>    — the equipped wheel set, under the chassis outlines.
///   3. chassis.png — the static detail layer (windows, headlights, eyes,
///                    grille, bumper, outlines) with the paint area transparent.
///   4. roof/kente  — the equipped roof-kente trim, on top.
///
/// Any accessory whose PNG isn't bundled yet is silently skipped, so the app
/// runs on the plain painted bus until the art lands. One set of assets drives
/// the Compound preview, the world-map avatar and each Tro Tro Rally racer.
class TintableTroTro extends StatefulWidget {
  final Color bodyColor;

  /// Equipped cosmetic ids by category (e.g. {'rim': 'rim_gold'}). Empty = the
  /// plain painted bus (used by rally racers, which only vary by colour).
  final Map<String, String> equipped;
  final double width;

  const TintableTroTro({
    super.key,
    required this.bodyColor,
    this.equipped = const {},
    this.width = 160,
  });

  @override
  State<TintableTroTro> createState() => _TintableTroTroState();
}

class _TintableTroTroState extends State<TintableTroTro> {
  static const String _dir = 'assets/mascot/trotro_gameplay/';
  static const double _aspect = 2636 / 1600; // gameplay chassis source bbox
  // The gameplay bus bakes its chrome wheels into the chassis, so every
  // accessory (gold rims, roof-kente trim) layers OVER the chassis.
  static const List<String> _underChassis = <String>[];
  static const List<String> _overChassis = ['rim', 'roof', 'kente'];

  Widget? _accessory(String category) {
    final id = widget.equipped[category];
    if (id == null) return null;
    // Render the layer directly. If the art isn't bundled yet, the errorBuilder
    // skips it silently — no dependency on AssetManifest.json, which isn't
    // reliably loadable on newer Flutter and was hiding *bundled* layers too.
    return Image.asset(
      '$_dir$category/$id.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[
      // 1 · tinted paintwork (mask)
      ColorFiltered(
        colorFilter: ColorFilter.mode(widget.bodyColor, BlendMode.modulate),
        child: const Image(
          image: AssetImage('${_dir}mask.png'),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    ];
    // 2 · rims (under the chassis outlines)
    for (final category in _underChassis) {
      final layer = _accessory(category);
      if (layer != null) layers.add(layer);
    }
    // 3 · chassis detail (windows, headlights, outlines)
    layers.add(const Image(
      image: AssetImage('${_dir}chassis.png'),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ));
    // 4 · roof-kente trim (on top)
    for (final category in _overChassis) {
      final layer = _accessory(category);
      if (layer != null) layers.add(layer);
    }

    return SizedBox(
      width: widget.width,
      height: widget.width / _aspect,
      child: Stack(fit: StackFit.expand, children: layers),
    );
  }
}
