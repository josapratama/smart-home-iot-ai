import 'package:cloud_firestore/cloud_firestore.dart';

class Device {
  final String id;
  final String name;
  final String roomId;
  final String type;
  final bool isOnline;
  final DateTime lastSeen;
  final List<Channel> channels;

  const Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.isOnline,
    required this.lastSeen,
    this.channels = const [],
  });

  factory Device.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final lastSeen = (d['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Anggap offline jika lastSeen lebih dari 2 menit yang lalu
    // (interval status ESP32 = 30 detik, jadi 2 menit = toleransi 4x miss)
    final isOnlineRaw = d['isOnline'] as bool? ?? false;
    final isStale = DateTime.now().difference(lastSeen).inMinutes >= 2;
    final isOnline = isOnlineRaw && !isStale;

    return Device(
      id: doc.id,
      name: d['name'] as String? ?? 'Perangkat',
      roomId: d['roomId'] as String? ?? '',
      type: d['type'] as String? ?? 'relay',
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }
}

class Channel {
  final String id;
  final String name;
  final int pin;
  final bool state;

  const Channel({
    required this.id,
    required this.name,
    required this.pin,
    required this.state,
  });

  factory Channel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Channel(
      id: doc.id,
      name: d['name'] as String,
      pin: d['pin'] as int,
      state: d['state'] as bool? ?? false,
    );
  }
}
