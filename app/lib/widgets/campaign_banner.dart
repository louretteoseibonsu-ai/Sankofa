import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';

/// The campaign hero banner — the rich isometric map art at the top of the world
/// map / home hub, framed velvet-dark with an editorial title overlay and a
/// legibility gradient.
class CampaignBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String kicker;
  final double height;

  const CampaignBanner({
    super.key,
    this.title = 'Sankofa',
    this.subtitle = 'Go Back and Get It',
    this.kicker = '',
    this.height = 148,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/hero/campaign_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: kVelvetBottom),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x11000000), Color(0xD9100C0A)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (kicker.isNotEmpty) ...[
                      Text(kicker.toUpperCase(), style: microLabel(color: kOchre)),
                      const SizedBox(height: 3),
                    ],
                    Text(title,
                        style: displayFont(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: kVelvetInk)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(subtitle,
                          style: displayFont(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE6D3A6))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
