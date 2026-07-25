import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'animations.dart';
import 'app_avatar.dart';
import 'greeting.dart';
import 'velvet.dart';

/// A personalised "Ayɛkoo, {name}!" celebration for a milestone (level-up,
/// boss defeat, 3-star mastery). Confetti + sound + haptic + the user's avatar.
/// Auto-dismisses after a few seconds.
Future<void> celebrateMilestone(
  BuildContext context, {
  required String headline,
  required String subline,
}) async {
  SoundService.instance.complete();
  HapticFeedback.heavyImpact();
  celebrateBurst(context);
  final name = firstNameOf(FirebaseAuth.instance.currentUser);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) {
      // Auto-dismiss so it never blocks the flow.
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      });
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AtmosphericPanel(
          radius: 24,
          glow: terracotta,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kOchre, width: 2),
                ),
                child: AppAvatar(
                    user: FirebaseAuth.instance.currentUser, radius: 34),
              ),
              const SizedBox(height: 16),
              Text(headline,
                  textAlign: TextAlign.center,
                  style: displayFont(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kVelvetInk)),
              const SizedBox(height: 4),
              Text('Ayɛkoo, $name!',
                  textAlign: TextAlign.center,
                  style: displayFont(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: terracotta)),
              const SizedBox(height: 6),
              Text(subline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kVelvetMuted, fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Medaase 🎉'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
