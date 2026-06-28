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

  Future<void> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

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

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
