
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialiser() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> afficher({
    required int id,
    required String titre,
    required String message,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'agrismart_alertes',
        'Alertes AgriSmart',
        channelDescription:
        'Notifications concernant les zones et la météo',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.show(
      id,
      titre,
      message,
      details,
    );
  }
}
