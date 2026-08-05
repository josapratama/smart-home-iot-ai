import 'package:cloud_firestore/cloud_firestore.dart';

class SensorReading {
  final String id;
  final String homeId;
  final String type;
  // PZEM fields
  final double? voltage;
  final double? current;
  final double? power;
  final double? energy;
  final double? frequency;
  final double? pf;
  // Legacy fields
  final int? gasPpm;
  final bool? gasAlert;
  final bool? flameDetected;
  final int? flameAnalog;
  final int? binLevel;
  final DateTime timestamp;

  const SensorReading({
    required this.id,
    required this.homeId,
    required this.type,
    this.voltage,
    this.current,
    this.power,
    this.energy,
    this.frequency,
    this.pf,
    this.gasPpm,
    this.gasAlert,
    this.flameDetected,
    this.flameAnalog,
    this.binLevel,
    required this.timestamp,
  });

  factory SensorReading.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Timestamp bisa berupa Firestore Timestamp atau tidak ada
    DateTime ts;
    if (d['timestamp'] is Timestamp) {
      ts = (d['timestamp'] as Timestamp).toDate();
    } else {
      // Fallback: gunakan waktu sekarang
      ts = DateTime.now();
    }

    return SensorReading(
      id: doc.id,
      homeId: d['homeId'] as String? ?? '',
      type: d['type'] as String? ?? 'energy',
      voltage: (d['voltage'] as num?)?.toDouble(),
      current: (d['current'] as num?)?.toDouble(),
      power: (d['power'] as num?)?.toDouble(),
      energy: (d['energy'] as num?)?.toDouble(),
      frequency: (d['frequency'] as num?)?.toDouble(),
      pf: (d['pf'] as num?)?.toDouble(),
      gasPpm: d['gasPpm'] as int?,
      gasAlert: d['gasAlert'] as bool?,
      flameDetected: d['flameDetected'] as bool?,
      flameAnalog: d['flameAnalog'] as int?,
      binLevel: d['binLevel'] as int?,
      timestamp: ts,
    );
  }
}
