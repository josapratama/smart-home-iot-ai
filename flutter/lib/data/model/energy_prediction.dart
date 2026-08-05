import 'package:cloud_firestore/cloud_firestore.dart';

class EnergyPrediction {
  final String id;
  final String homeId;
  final String deviceId;
  final double predictedKwh;
  final double actualKwh;
  final double mape;
  final DateTime createdAt;

  const EnergyPrediction({
    required this.id,
    required this.homeId,
    required this.deviceId,
    required this.predictedKwh,
    required this.actualKwh,
    required this.mape,
    required this.createdAt,
  });

  factory EnergyPrediction.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EnergyPrediction(
      id: doc.id,
      homeId: d['homeId'] as String? ?? '',
      deviceId: d['deviceId'] as String? ?? '',
      predictedKwh: (d['predictedKwh'] as num).toDouble(),
      actualKwh: (d['actualKwh'] as num).toDouble(),
      mape: (d['mape'] as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }
}
