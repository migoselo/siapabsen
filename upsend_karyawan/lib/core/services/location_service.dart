import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationMonitor {
	StreamSubscription<Position>? _subscription;
	Timer? _debugTimer;

	Future<void> start({
		required double targetLatitude,
		required double targetLongitude,
		required double radiusMeters,
		required void Function(double distance) onOutsideRadius,
		bool simulateOutsideRadius = false,
	}) async {
		await stop();

		if (simulateOutsideRadius) {
			_debugTimer = Timer(const Duration(seconds: 2), () {
				onOutsideRadius(radiusMeters + 2);
			});
		}

		if (!await Geolocator.isLocationServiceEnabled()) return;

		var permission = await Geolocator.checkPermission();
		if (permission == LocationPermission.denied) {
			permission = await Geolocator.requestPermission();
		}
		if (permission == LocationPermission.denied ||
				permission == LocationPermission.deniedForever) {
			return;
		}

		var wasOutside = false;
		final settings = const LocationSettings(
			accuracy: LocationAccuracy.high,
			distanceFilter: 5,
		);

		_subscription = Geolocator.getPositionStream(
			locationSettings: settings,
		).listen((position) {
			final distance = Geolocator.distanceBetween(
				position.latitude,
				position.longitude,
				targetLatitude,
				targetLongitude,
			);
			final isOutside = distance > radiusMeters;
			if (isOutside && !wasOutside) {
				onOutsideRadius(distance);
			}
			wasOutside = isOutside;
		});
	}

	Future<void> stop() async {
		_debugTimer?.cancel();
		_debugTimer = null;
		await _subscription?.cancel();
		_subscription = null;
	}
}
