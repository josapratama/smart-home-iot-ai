import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_home/firebase_options.dart';
import 'package:smart_home/utils/notification_service.dart';
import 'package:smart_home/ui/router.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

// Handler notifikasi saat app di background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showLocalNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale data untuk intl (DateFormat dengan locale 'id')
  await initializeDateFormatting('id', null);

  // Status bar transparan — icon terang untuk dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  runApp(const ProviderScope(child: SmartHomeApp()));
}

class SmartHomeApp extends ConsumerWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Selalu dark — gelap & tidak mencolok
      routerConfig: router,
    );
  }
}
