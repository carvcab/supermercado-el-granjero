import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notif {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static Future<void> show(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('stock_alerts', 'Alertas Stock', importance: Importance.high, priority: Priority.high),
      ),
    );
  }
}
