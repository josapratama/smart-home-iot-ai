import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Setup local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotif.initialize(initSettings);

    // Buat channel notifikasi alarm (Android)
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Bahaya',
      description: 'Notifikasi untuk alarm kebakaran dan kebocoran gas',
      importance: Importance.max,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alarmChannel);

    // Minta izin notifikasi
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle notifikasi saat app di foreground
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(message);
    });
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Bahaya',
          channelDescription:
              'Notifikasi untuk alarm kebakaran dan kebocoran gas',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Ambil FCM token untuk disimpan ke Firestore
  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}
