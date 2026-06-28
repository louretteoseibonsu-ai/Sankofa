import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/plan_picker_screen.dart';
import 'services/auth_service.dart';

/// Shows the login screen when signed out, the app when signed in —
/// with a one-time plan picker after a new sign-up.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
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

  @override
  void initState() {
    super.initState();
    AuthService().needsPlanChoice().then((v) {
      if (mounted) setState(() => _needsPlan = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsPlan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsPlan == true) {
      return PlanPickerScreen(
        onDone: () => setState(() => _needsPlan = false),
      );
    }
    return const AppShell();
  }
}
