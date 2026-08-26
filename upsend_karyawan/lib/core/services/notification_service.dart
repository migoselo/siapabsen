import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
        'attendance_radius',
        'Pengingat Absensi',
        description: 'Notifikasi ketika user keluar dari radius absensi.',
        importance: Importance.high,
      );

  Future<void> initialize({bool requestPermission = true}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    // Remove the old foreground-service notification from previous app versions.
    await _plugin.cancel(2001);

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_channel);
    if (requestPermission) {
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> showOutsideRadius({required int distanceMeters}) {
    return _plugin.show(
      1001,
      'Pengingat checkout',
      'Anda berada di luar radius absensi ($distanceMeters m). Jangan lupa checkout.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_radius',
          'Pengingat Absensi',
          channelDescription:
              'Notifikasi ketika user keluar dari radius absensi.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_foreground',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
