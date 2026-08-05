import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/repository/auth_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Stream profil user dari Firestore — reaktif terhadap perubahan auth
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return UserRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ).watchProfile(uid);
});

/// Provider homeId yang hanya update dari server (bukan cache)
/// Mencegah false-null saat cache belum punya activeHomeId
final homeIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  // Kalau masih loading, return null
  if (!profile.hasValue) return null;
  return profile.value?.homeId;
});

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Stream profil user realtime
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  /// Ambil homeId pertama yang dimiliki user
  Future<String?> getFirstHomeId(String uid) async {
    final snap = await _firestore
        .collection('homes')
        .where('memberUids', arrayContains: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// Set homeId aktif di profil user
  Future<void> setActiveHome(String homeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    // Pakai set+merge agar bekerja meski dokumen belum punya field activeHomeId
    await _firestore.collection('users').doc(uid).set(
      {'activeHomeId': homeId},
      SetOptions(merge: true),
    );
  }

  /// Buat rumah baru, return homeId yang dibuat
  Future<String> createHome(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User tidak login');

    final doc = await _firestore.collection('homes').add({
      'name': name,
      'ownerUid': uid,
      'memberUids': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Cek apakah homeId ada di Firestore
  Future<bool> homeExists(String homeId) async {
    if (homeId.isEmpty) return false;
    final doc = await _firestore.collection('homes').doc(homeId).get();
    return doc.exists;
  }

  /// Gabung ke rumah yang sudah ada (tambahkan uid ke memberUids)
  Future<void> joinHome(String homeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User tidak login');

    await _firestore.collection('homes').doc(homeId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
  }
}

class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? homeId; // activeHomeId di Firestore
  final String role;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.homeId,
    this.role = 'user',
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] as String?,
      email: d['email'] as String?,
      photoUrl: d['photoUrl'] as String?,
      homeId: d['activeHomeId'] as String?,
      role: d['role'] as String? ?? 'user',
    );
  }
}
