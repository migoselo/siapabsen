import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

const _latitudeKey = 'radius_target_latitude';
const _longitudeKey = 'radius_target_longitude';
const _radiusKey = 'radius_target_meters';
const _activeKey = 'radius_monitor_active';
const _monitorChannelId = 'radius_monitor_service';
const _monitorNotificationId = 2001;

class BackgroundRadiusService {
  BackgroundRadiusService._();

  static final BackgroundRadiusService instance = BackgroundRadiusService._();
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> configure() async {
    const channel = AndroidNotificationChannel(
      _monitorChannelId,
      'Pemantauan lokasi absensi',
      description: 'Menjaga pemantauan radius saat sesi check-in aktif.',
      importance: Importance.low,
    );

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _monitorChannelId,
        initialNotificationTitle: 'SiapAbsen',
        initialNotificationContent: 'Memantau lokasi absensi',
        foregroundServiceNotificationId: _monitorNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  Future<void> start({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_latitudeKey, latitude);
    await preferences.setDouble(_longitudeKey, longitude);
    await preferences.setDouble(_radiusKey, radiusMeters);
    await preferences.setBool(_activeKey, true);

    if (await _service.isRunning()) {
      _service.invoke('refresh');
    } else {
      await _service.startService();
    }
  }

  Future<void> stop() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activeKey, false);
    _service.invoke('stop');
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notifications = NotificationService.instance;
  await notifications.initialize(requestPermission: false);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('stop').listen((_) {
      service.stopSelf();
    });
  }

  var wasOutside = false;
  var simulationSent = false;

  Future<void> checkRadius() async {
    final preferences = await SharedPreferences.getInstance();
    final isActive = preferences.getBool(_activeKey) ?? false;
    if (!isActive) return;

    final latitude = preferences.getDouble(_latitudeKey);
    final longitude = preferences.getDouble(_longitudeKey);
    final radius = preferences.getDouble(_radiusKey);
    if (latitude == null || longitude == null || radius == null) return;

    const simulate = bool.fromEnvironment(
      'SIMULATE_RADIUS_NOTIFICATION',
      defaultValue: false,
    );
    if (simulate && !simulationSent) {
      simulationSent = true;
      wasOutside = true;
      await notifications.showOutsideRadius(
        distanceMeters: radius.round() + 2,
      );
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) return;
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
    final isOutside = distance > radius;
    if (isOutside && !wasOutside) {
      await notifications.showOutsideRadius(distanceMeters: distance.round());
    }
    wasOutside = isOutside;
  }

  Timer.periodic(const Duration(seconds: 15), (_) async {
    try {
      await checkRadius();
    } catch (_) {
      // Location can temporarily be unavailable while the device changes state.
    }
  });
}
