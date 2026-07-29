import 'package:flutter/material.dart';

/// The branded loading screen shown while the app boots (auth + first sync).
/// Velvet-dark with the app mark, so there is no white flash between the native
/// launch screen and the first real screen — the whole cold start reads as one
/// intentional splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF141416), // brand velvet — matches the native launch bg
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Image(
                image: AssetImage('assets/icon/app_icon.png'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 26),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Color(0xFFE3A92C)), // ochre
              ),
            ),
          ],
        ),
      ),
    );
  }
}
