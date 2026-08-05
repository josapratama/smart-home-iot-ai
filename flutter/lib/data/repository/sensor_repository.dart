import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/sensor_reading.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return SensorRepository(FirebaseFirestore.instance);
});

class SensorRepository {
  final FirebaseFirestore _db;
  SensorRepository(this._db);

  /// Stream data sensor terbaru — semua tipe (energy, gas, fire, bin)
  /// Menggunakan dua query paralel:
  /// 1. Query dengan orderBy untuk dokumen baru (ada timestamp)
  /// 2. Query tanpa orderBy sebagai fallback jika index belum siap
  Stream<List<SensorReading>> watchLatestReadings(String homeId) {
    return _db
        .collection('sensor_readings')
        .where('homeId', isEqualTo: homeId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(SensorReading.fromFirestore).toList())
        .handleError((_) {
      // Fallback: tanpa orderBy jika index belum siap atau dokumen tidak punya timestamp
      return _db
          .collection('sensor_readings')
          .where('homeId', isEqualTo: homeId)
          .limit(50)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map(SensorReading.fromFirestore).toList();
        // Sort di client side berdasarkan timestamp descending
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
    });
  }

  /// Ambil data historis energi 7 hari terakhir untuk grafik
  Future<List<SensorReading>> getEnergyHistory(String homeId) async {
    final since = Timestamp.fromDate(
      DateTime.now().toUtc().subtract(const Duration(days: 7)),
    );
    final snap = await _db
        .collection('sensor_readings')
        .where('homeId', isEqualTo: homeId)
        .where('type', isEqualTo: 'energy')
        .where('timestamp', isGreaterThanOrEqualTo: since)
        .orderBy('timestamp', descending: false)
        .limit(1008) // maks ~6 reading/jam × 24 jam × 7 hari
        .get();
    return snap.docs.map(SensorReading.fromFirestore).toList();
  }
}
