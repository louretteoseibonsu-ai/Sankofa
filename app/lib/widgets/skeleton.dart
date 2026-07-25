import 'package:flutter/material.dart';

const Color _base = Color(0xFFE9E6DF);
const Color _highlight = Color(0xFFF6F4EF);
const Color _cardBorder = Color(0xFFECE8E0);

/// Drives a single in-sync pulse for all [SkeletonBox]es beneath it.
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => _SkeletonScope(value: _c.value, child: child!),
      );
}

class _SkeletonScope extends InheritedWidget {
  final double value;
  const _SkeletonScope({required this.value, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.value ??
      0.5;

  @override
  bool updateShouldNotify(_SkeletonScope old) => old.value != value;
}

/// A grey placeholder block that pulses between base and highlight.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(_base, _highlight, _SkeletonScope.of(context)),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// One placeholder "row" — an icon disc + two text bars in a card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(
        children: const [
          SkeletonBox(width: 26, height: 26, radius: 13),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 15),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A ready-made loading placeholder for list screens: an optional header pair
/// plus [rows] shimmering cards.
class SkeletonListView extends StatelessWidget {
  final int rows;
  final bool header;
  const SkeletonListView({super.key, this.rows = 5, this.header = true});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (header) ...[
            const SkeletonBox(width: 210, height: 26),
            const SizedBox(height: 10),
            const SkeletonBox(width: 250, height: 13),
            const SizedBox(height: 20),
          ],
          for (int i = 0; i < rows; i++) const SkeletonCard(),
        ],
      ),
    );
  }
}
