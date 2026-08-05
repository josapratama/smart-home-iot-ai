import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/device.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(FirebaseFirestore.instance);
});

class DeviceRepository {
  final FirebaseFirestore _db;
  DeviceRepository(this._db);

  /// Stream daftar perangkat dalam sebuah rumah (realtime)
  Stream<List<Device>> watchDevices(String homeId) {
    return _db
        .collection('homes')
        .doc(homeId)
        .collection('devices')
        .snapshots()
        .map((snap) => snap.docs.map(Device.fromFirestore).toList());
  }

  /// Stream channel (relay) dari sebuah perangkat (realtime)
  Stream<List<Channel>> watchChannels(String homeId, String deviceId) {
    return _db
        .collection('homes')
        .doc(homeId)
        .collection('devices')
        .doc(deviceId)
        .collection('channels')
        .snapshots()
        .map((snap) => snap.docs.map(Channel.fromFirestore).toList());
  }

  /// Kirim perintah on/off ke Firestore
  /// Cloud Function akan forward ke MQTT → ESP32
  Future<void> sendCommand({
    required String homeId,
    required String deviceId,
    required int channelPin,
    required bool state,
    required String sentBy,
  }) async {
    // 1. Update state channel langsung → UI update instan
    await updateChannelState(
      homeId: homeId,
      deviceId: deviceId,
      channelPin: channelPin,
      state: state,
    );

    // 2. Kirim command ke MQTT via Firestore (async, tidak perlu await)
    _db.collection('commands').add({
      'homeId': homeId,
      'deviceId': deviceId,
      'channelPin': channelPin,
      'action': state ? 'on' : 'off',
      'sentBy': sentBy,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update state channel langsung di Firestore
  /// Dipanggil untuk optimistic UI update
  Future<void> updateChannelState({
    required String homeId,
    required String deviceId,
    required int channelPin,
    required bool state,
  }) async {
    // Cari channel berdasarkan pin
    final snap = await _db
        .collection('homes')
        .doc(homeId)
        .collection('devices')
        .doc(deviceId)
        .collection('channels')
        .where('pin', isEqualTo: channelPin)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    await snap.docs.first.reference.update({'state': state});
  }
}
