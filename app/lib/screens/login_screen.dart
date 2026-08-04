import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'legal_screen.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

/// Official multi-color Google "G" logo.
const String _googleGLogo = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _captcha = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  bool _emailTaken = false; // show a "Sign in instead" shortcut
  bool _acceptedTerms = false; // GDPR: explicit opt-in at sign-up
  int _capA = 0, _capB = 0;
  late final TapGestureRecognizer _tapPrivacy;
  late final TapGestureRecognizer _tapTerms;

  @override
  void initState() {
    super.initState();
    _newCaptcha();
    _tapPrivacy = TapGestureRecognizer()
      ..onTap = () => _openLegal('Privacy Policy', kPrivacyPolicy);
    _tapTerms = TapGestureRecognizer()
      ..onTap = () => _openLegal('Terms & Conditions', kTermsAndConditions);
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LegalScreen(title: title, body: body)));
  }

  void _newCaptcha() {
    final r = Random();
    _capA = 1 + r.nextInt(8);
    _capB = 1 + r.nextInt(8);
    _captcha.clear();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _captcha.dispose();
    _tapPrivacy.dispose();
    _tapTerms.dispose();
    super.dispose();
  }

  static final _emailRe =
      RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$");

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final pw = _password.text;
    // Client-side validation before hitting Firebase.
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_isRegister && int.tryParse(_captcha.text.trim()) != _capA + _capB) {
      setState(() {
        _error = 'Security check failed — please solve the sum.';
        _newCaptcha();
      });
      return;
    }
    if (_isRegister && !_acceptedTerms) {
      setState(() => _error =
          'Please accept the Terms & Privacy Policy to create an account.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _emailTaken = false;
    });
    try {
      if (_isRegister) {
        await _auth.registerWithEmail(email, pw);
        // Record proof of consent (policy version + timestamp) for GDPR.
        await _auth.recordConsent(kLegalVersion);
      } else {
        await _auth.signInWithEmail(email, pw);
      }
      // AuthGate will swap to the app automatically on success.
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendly(e);
        // Duplicate email on sign-up (or email registered via Google) — offer
        // a one-tap switch to Sign in instead of letting them retry forever.
        _emailTaken = _isRegister &&
            (e.code == 'email-already-in-use' ||
                e.code == 'account-exists-with-different-credential');
      });
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?".');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (_) {
      setState(() => _error = 'Could not send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'An account already exists for that email. Sign in instead?';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sankofa Twi',
                    textAlign: TextAlign.center,
                    style: displayFont(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kVelvetInk),
                  ),
                  Text(
                    _isRegister ? 'Create your account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kVelvetMuted),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            label: Text('Sign in'),
                            icon: Icon(Icons.login, size: 16)),
                        ButtonSegment(
                            value: true,
                            label: Text('Create account'),
                            icon: Icon(Icons.person_add_alt, size: 16)),
                      ],
                      selected: {_isRegister},
                      onSelectionChanged: _loading
                          ? null
                          : (s) => setState(() {
                                _isRegister = s.first;
                                _error = null;
                                _emailTaken = false;
                              }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _captcha,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Security check:  $_capA + $_capB = ?',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: _loading
                                ? null
                                : (v) => setState(() {
                                      _acceptedTerms = v ?? false;
                                      if (_acceptedTerms) _error = null;
                                    }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                    color: kVelvetInk, fontSize: 13, height: 1.4),
                                children: [
                                  const TextSpan(text: 'I have read and agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(
                                        color: terracotta,
                                        fontWeight: FontWeight.w700),
                                    recognizer: _tapTerms,
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                        color: terracotta,
                                        fontWeight: FontWeight.w700),
                                    recognizer: _tapPrivacy,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!_isRegister)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: accentCoral)),
                  ],
                  if (_emailTaken) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign in with this email'),
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _isRegister = false;
                                  _error = null;
                                  _emailTaken = false;
                                  // Keep the email they typed; clear password.
                                  _password.clear();
                                }),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submitEmail,
                    child: _loading
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isRegister ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: kVelvetMuted)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading ? null : _google,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3C4043),
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(_googleGLogo, width: 20, height: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isRegister = !_isRegister;
                              _error = null;
                              _emailTaken = false;
                            }),
                    child: Text(_isRegister
                        ? 'Already have an account? Sign in'
                        : "New here? Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
