import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/MyApp.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

final supabase = Supabase.instance.client;

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificações Importantes',
  description: "Este canal é usado para notificações vitais para o uso do app.",
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showNotificationWithAvatar(RemoteMessage message) async {
  final title =
      message.notification?.title ??
      message.data['title'] ??
      'Nova notificação';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  final avatarUrl =
      message.data['avatar_url'] ??
      message.data['user_avatar_url'] ??
      message.data['avatar'] ??
      message.data['user_avatar'];

  ByteArrayAndroidBitmap? largeIcon;
  if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(avatarUrl.toString()));
      if (response.statusCode == 200) {
        largeIcon = ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      debugPrint("Erro ao carregar avatar para a notificação: $e");
    }
  }

  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.high,
    priority: Priority.high,
    largeIcon: largeIcon,
    icon: '@mipmap/ic_launcher',
  );

  final notificationDetails = NotificationDetails(android: androidDetails);

  final notificationId = message.messageId != null
      ? message.messageId.hashCode
      : DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await flutterLocalNotificationsPlugin.show(
    id: notificationId,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
    payload: message.data['payload'] ?? message.data['route'],
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await showNotificationWithAvatar(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yombhmzdpmffekqhdtrv.supabase.co',
    anonKey: 'sb_publishable_WnnTd11M1Lv_n5ookD45uQ_ZJYzav3l',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotificationWithAvatar(message);
  });

  AuthRepository.startSessionListener();
  AuthRepository.initFirebaseMessaging();

  runApp(const MyApp());
}
