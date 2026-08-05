import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/energy_prediction.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepository(FirebaseFirestore.instance);
});

/// Data anomali dari Firestore /anomaly_results
class AnomalyResult {
  final String id;
  final String homeId;
  final bool isAnomaly;
  final String status; // "normal" | "anomaly"
  final double score;
  final DateTime createdAt;

  const AnomalyResult({
    required this.id,
    required this.homeId,
    required this.isAnomaly,
    required this.status,
    required this.score,
    required this.createdAt,
  });

  factory AnomalyResult.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnomalyResult(
      id: doc.id,
      homeId: d['homeId'] as String? ?? '',
      isAnomaly: d['isAnomaly'] as bool? ?? false,
      status: d['status'] as String? ?? 'normal',
      score: (d['score'] as num?)?.toDouble() ?? 0.0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PredictionRepository {
  final FirebaseFirestore _db;
  PredictionRepository(this._db);

  /// Prediksi energi terbaru untuk home tertentu
  Stream<EnergyPrediction?> watchLatestPrediction(String homeId) {
    return _db
        .collection('energy_predictions')
        .where('homeId', isEqualTo: homeId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : EnergyPrediction.fromFirestore(snap.docs.first));
  }

  /// Hasil anomali terbaru
  Stream<AnomalyResult?> watchLatestAnomaly(String homeId) {
    return _db
        .collection('anomaly_results')
        .where('homeId', isEqualTo: homeId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : AnomalyResult.fromFirestore(snap.docs.first));
  }
}
