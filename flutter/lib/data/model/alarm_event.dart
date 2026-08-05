import 'package:cloud_firestore/cloud_firestore.dart';

class AlarmEvent {
  final String id;
  final String homeId;
  final String type; // "gas" | "fire" | "anomaly"
  final String severity; // "low" | "medium" | "high"
  final String message;
  final bool isResolved;
  final DateTime triggeredAt;

  const AlarmEvent({
    required this.id,
    required this.homeId,
    required this.type,
    required this.severity,
    required this.message,
    required this.isResolved,
    required this.triggeredAt,
  });

  factory AlarmEvent.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // triggeredAt bisa null pada dokumen lama dari firmware yang belum fix
    DateTime triggeredAt;
    if (d['triggeredAt'] is Timestamp) {
      triggeredAt = (d['triggeredAt'] as Timestamp).toDate();
    } else {
      triggeredAt = DateTime.now();
    }

    return AlarmEvent(
      id: doc.id,
      homeId: d['homeId'] as String? ?? '',
      type: d['type'] as String? ?? 'unknown',
      severity: d['severity'] as String? ?? 'medium',
      message: d['message'] as String? ?? '',
      isResolved: d['isResolved'] as bool? ?? false,
      triggeredAt: triggeredAt,
    );
  }
}
