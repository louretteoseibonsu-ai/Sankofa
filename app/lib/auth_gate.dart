import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/plan_picker_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'widgets/splash_screen.dart';

/// Shows the login screen when signed out, the app when signed in —
/// with a one-time plan picker after a new sign-up, and a block for
/// accounts an admin has suspended.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data == null) return const LoginScreen();
        return const _SignedInRouter();
      },
    );
  }
}

class _SignedInRouter extends StatefulWidget {
  const _SignedInRouter();

  @override
  State<_SignedInRouter> createState() => _SignedInRouterState();
}

class _SignedInRouterState extends State<_SignedInRouter> {
  bool? _needsPlan;
  bool _needsOnboarding = false;
  bool _disabled = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    // Mirror account info into Firestore so the admin panel can list this user.
    await auth.syncUserDoc();
    // Register for push nudges (best-effort; prompts for permission).
    NotificationService.instance.register();
    final disabled = await auth.isDisabled();
    final needsPlan = disabled ? false : await auth.needsPlanChoice();
    final needsOnboarding = disabled ? false : await auth.needsOnboarding();
    if (!mounted) return;
    setState(() {
      _disabled = disabled;
      _needsPlan = needsPlan;
      _needsOnboarding = needsOnboarding;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SplashScreen();
    }
    if (_disabled) return const _SuspendedScreen();
    if (_needsPlan == true) {
      return PlanPickerScreen(
        onDone: () => setState(() => _needsPlan = false),
      );
    }
    if (_needsOnboarding) {
      return OnboardingScreen(
        onDone: () => setState(() => _needsOnboarding = false),
      );
    }
    return const AppShell();
  }
}

/// Shown when an admin has suspended the account.
class _SuspendedScreen extends StatelessWidget {
  const _SuspendedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 56, color: Color(0xFF9B2D2A)),
                const SizedBox(height: 16),
                const Text('Account suspended',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 22, color: ink)),
                const SizedBox(height: 10),
                const Text(
                  'Your account has been suspended. If you think this is a '
                  'mistake, contact us at sankofa@aparato.ai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: slate, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                  onPressed: () => AuthService().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
