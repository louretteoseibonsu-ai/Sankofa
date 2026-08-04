import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth: email/password + Google Sign-In.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Send a verification link to confirm the email is real.
    await cred.user?.sendEmailVerification();
  }

  /// Re-sends the verification email to the current user.
  Future<void> resendVerification() async {
    await _u?.reload();
    final u = _u;
    if (u != null && !u.emailVerified) await u.sendEmailVerification();
  }

  bool get isEmailVerified => _u?.emailVerified ?? false;
  bool get isPasswordUser =>
      _u?.providerData.any((p) => p.providerId == 'password') ?? false;

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // user cancelled the chooser
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  // ── Profile / avatar ────────────────────────────────────────────────────
  User? get _u => _auth.currentUser;

  Future<void> updateDisplayName(String name) async {
    await _u?.updateDisplayName(name.trim());
    await _u?.reload();
  }

  /// Adinkra avatars are stored in photoURL as a token: adinkra://<glyphId>/<HEX>.
  Future<void> setAdinkraAvatar(String glyphId, String hexColor) async {
    await _u?.updatePhotoURL('adinkra://$glyphId/$hexColor');
    await _u?.reload();
  }

  /// Uploads a photo to Firebase Storage and points photoURL at it.
  Future<void> uploadPhotoAvatar(File file) async {
    final uid = _u!.uid;
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _u?.updatePhotoURL(url);
    await _u?.reload();
  }

  // ── Extended profile (Firestore: users/{uid}) ───────────────────────────
  /// Reads the user's extended profile doc. Returns {} if none / signed out.
  Future<Map<String, dynamic>> loadProfile() async {
    final uid = _u?.uid;
    if (uid == null) return {};
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  /// Merges profile fields into users/{uid}. Only non-null fields are written.
  Future<void> saveProfile({String? dob, String? gender, String? dayName}) async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (dayName != null) 'dayName': dayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marks the account as premium. NOTE: placeholder for real billing —
  /// replace the call site with a verified `in_app_purchase` receipt before
  /// shipping. This only flips a Firestore flag.
  /// Mirrors basic account info into users/{uid} so the admin panel can list
  /// sign-ups (email/name aren't in Firestore otherwise). Sets createdAt once.
  Future<void> syncUserDoc() async {
    final u = _u;
    if (u == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
    final snap = await ref.get();
    final data = <String, dynamic>{
      'email': u.email,
      'name': u.displayName,
      'lastSeen': FieldValue.serverTimestamp(),
    };
    if (!snap.exists || snap.data()?['createdAt'] == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
  }

  /// True if there is an admins/{uid} doc for the current user.
  Future<bool> isAdmin() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    return doc.exists;
  }

  /// True if an admin has suspended this account.
  Future<bool> isDisabled() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['disabled'] as bool?) ?? false;
  }

  /// Records that the user accepted the Terms & Privacy Policy at sign-up,
  /// with the policy version and a server timestamp — proof of consent for
  /// GDPR. Stored on the user doc; safe to call right after registration.
  Future<void> recordConsent(String version) async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'termsAcceptedVersion': version,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// True until the user has seen the Free/Premium plan picker after sign-up.
  Future<bool> needsPlanChoice() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return !((doc.data()?['planChosen'] as bool?) ?? false);
  }

  Future<void> markPlanChosen() async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'planChosen': true}, SetOptions(merge: true));
  }

  /// True until the learner completes the one-time "why Twi?" onboarding.
  Future<bool> needsOnboarding() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return !((doc.data()?['onboarded'] as bool?) ?? false);
  }

  /// Stores the learner's motivation + region and marks onboarding complete.
  Future<void> saveOnboarding(
      {required String intent, required String region}) async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'onboarded': true,
      'onboardingIntent': intent,
      'onboardingRegion': region,
    }, SetOptions(merge: true));
  }

  /// True until the user has seen the one-time first-run app tour.
  Future<bool> needsAppTour() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return !((doc.data()?['appTourSeen'] as bool?) ?? false);
  }

  Future<void> markAppTourSeen() async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'appTourSeen': true}, SetOptions(merge: true));
  }

  /// True if the account currently has premium entitlement.
  Future<bool> isPremium() async {
    final uid = _u?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['premium'] as bool?) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final uid = _u?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'premium': value,
      'premiumSince': value ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }

  /// Permanently deletes the user's data and Auth account. Firebase requires a
  /// recent login to delete; if the session is old we re-authenticate first
  /// (with [password] for email users, or a fresh Google sign-in) and retry.
  Future<void> deleteAccount({String? password}) async {
    var u = _u;
    if (u == null) return;
    try {
      await _wipeAndDelete(u);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticate(password: password);
        u = _u;
        if (u == null) return;
        await _wipeAndDelete(u);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _wipeAndDelete(User u) async {
    final db = FirebaseFirestore.instance;
    // Remove app data while still authenticated, then the Auth account.
    await db.collection('users').doc(u.uid).delete().catchError((_) {});
    await db.collection('leaderboard').doc(u.uid).delete().catchError((_) {});
    await u.delete();
  }

  /// Re-confirms the user's identity so a sensitive action (delete) can proceed.
  Future<void> _reauthenticate({String? password}) async {
    final u = _u;
    if (u == null) return;
    if (isPasswordUser) {
      final email = u.email;
      if (email == null || password == null || password.isEmpty) {
        throw FirebaseAuthException(
            code: 'password-required',
            message: 'Your password is required to confirm.');
      }
      final cred =
          EmailAuthProvider.credential(email: email, password: password);
      await u.reauthenticateWithCredential(cred);
    } else {
      // Google (or other provider) — re-run sign-in for a fresh credential.
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
            code: 'reauth-cancelled', message: 'Sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await u.reauthenticateWithCredential(credential);
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
