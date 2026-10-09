import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/feature/MyApp.dart';
import 'package:myapp/feature/NotificationRouter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repository/AuthRepository.dart';
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
    icon: '@drawable/ic_notification',
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
    payload: jsonEncode(message.data),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
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
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onMessageOpenedApp.listen((m) {});
  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@drawable/ic_notification',
  );

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (response) =>
        NotificationRouter.aoTocarNotificacaoLocal(response.payload),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  FirebaseMessaging.onMessageOpenedApp.listen(
    (m) => NotificationRouter.aoTocarNotificacaoFcm(m.data),
  );

  // App encerrado: aberto por notificação do sistema
  final inicial = await FirebaseMessaging.instance.getInitialMessage();
  if (inicial != null) NotificationRouter.aoTocarNotificacaoFcm(inicial.data);

  // App encerrado: aberto por notificação local
  final launch = await flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    NotificationRouter.aoTocarNotificacaoLocal(
      launch!.notificationResponse?.payload,
    );
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotificationWithAvatar(message);
  });

  AuthRepository.startSessionListener();
  AuthRepository.initFirebaseMessaging();
  runApp(const MyApp());
}
