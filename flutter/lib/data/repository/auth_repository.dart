import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Stream status auth — dipakai router untuk redirect
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    // Cek dan perbaiki activeHomeId jika hilang
    final uid = cred.user!.uid;
    final userDoc = _firestore.collection('users').doc(uid);
    final existing = await userDoc.get();
    if (existing.exists) {
      final data = existing.data() as Map<String, dynamic>;
      if (!data.containsKey('activeHomeId') || data['activeHomeId'] == null) {
        final homesSnap = await _firestore
            .collection('homes')
            .where('memberUids', arrayContains: uid)
            .limit(1)
            .get();
        if (homesSnap.docs.isNotEmpty) {
          await userDoc.update({'activeHomeId': homesSnap.docs.first.id});
        }
      }
    }

    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);

    // Update profil tanpa overwrite activeHomeId atau createdAt yang sudah ada
    final user = userCred.user!;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final existing = await userDoc.get();

    if (!existing.exists) {
      // Dokumen baru — buat dengan field dasar dulu
      await userDoc.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cari apakah UID ini sudah ada di rumah manapun
      final homesSnap = await _firestore
          .collection('homes')
          .where('memberUids', arrayContains: user.uid)
          .limit(1)
          .get();
      if (homesSnap.docs.isNotEmpty) {
        await userDoc.update({'activeHomeId': homesSnap.docs.first.id});
      }
    } else {
      // Dokumen sudah ada — hanya update field yang boleh berubah
      // JANGAN overwrite activeHomeId
      final updates = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      };

      // Jika belum punya activeHomeId, cari dari collection homes
      final existingData = existing.data() as Map<String, dynamic>;
      if (!existingData.containsKey('activeHomeId') ||
          existingData['activeHomeId'] == null) {
        // Cari rumah yang dimiliki user ini
        final homesSnap = await _firestore
            .collection('homes')
            .where('memberUids', arrayContains: user.uid)
            .limit(1)
            .get();
        if (homesSnap.docs.isNotEmpty) {
          updates['activeHomeId'] = homesSnap.docs.first.id;
        }
      }

      await userDoc.update(updates);
    }

    return userCred;
  }

  Future<UserCredential> register(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    // Simpan profil user ke Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': name,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // clearPersistence harus dipanggil setelah semua listener ditutup
    // Tidak bisa dipanggil saat ada stream aktif — skip untuk sekarang
  }

  /// Simpan FCM token ke profil user agar bisa menerima notifikasi
  Future<void> saveFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }
}
