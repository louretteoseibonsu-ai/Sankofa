import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an Adinkra symbol from its raw SVG string. The source SVGs are baked
/// in near-black (#2B2B2D); pass [color] to recolor the whole glyph so it stays
/// legible on dark surfaces.
class AdinkraGlyph extends StatelessWidget {
  final String svg;
  final double size;
  final Color? color;
  const AdinkraGlyph(
      {super.key, required this.svg, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svg,
        fit: BoxFit.contain,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      ),
    );
  }
}
