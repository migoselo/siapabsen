import 'dart:async';

import 'package:flutter/services.dart';

import 'notification_service.dart';

const _channel = MethodChannel('com.example.upsend_karyawan/radius');
const _simulateRadiusNotification = bool.fromEnvironment(
  'SIMULATE_RADIUS_NOTIFICATION',
  defaultValue: false,
);

class BackgroundRadiusService {
  BackgroundRadiusService._();

  static final BackgroundRadiusService instance = BackgroundRadiusService._();
  Future<void> configure() async {
    // Android restores the registered geofence through its PendingIntent.
  }

  Future<void> start({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    if (_simulateRadiusNotification) {
      Timer(const Duration(seconds: 2), () {
        NotificationService.instance.showOutsideRadius(
          distanceMeters: radiusMeters.round() + 2,
        );
      });
      return;
    }

    await _channel.invokeMethod('registerGeofence', {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radiusMeters,
    });
  }

  Future<void> stop() async {
    await _channel.invokeMethod('unregisterGeofence');
  }
}
