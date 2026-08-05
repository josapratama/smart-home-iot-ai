import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/alarm_event.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(FirebaseFirestore.instance);
});

class AlarmRepository {
  final FirebaseFirestore _db;
  AlarmRepository(this._db);

  /// Stream alarm aktif (belum resolved) — realtime
  Stream<List<AlarmEvent>> watchActiveAlarms(String homeId) {
    return _db
        .collection('alarm_events')
        .where('homeId', isEqualTo: homeId)
        .where('isResolved', isEqualTo: false)
        .orderBy('triggeredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AlarmEvent.fromFirestore).toList());
  }

  /// Riwayat semua alarm
  Future<List<AlarmEvent>> getAlarmHistory(String homeId) async {
    final snap = await _db
        .collection('alarm_events')
        .where('homeId', isEqualTo: homeId)
        .orderBy('triggeredAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(AlarmEvent.fromFirestore).toList();
  }

  /// Tandai alarm sebagai selesai
  Future<void> resolveAlarm(String alarmId) async {
    await _db.collection('alarm_events').doc(alarmId).update({
      'isResolved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
