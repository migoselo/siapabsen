import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> openPermissionSettings() async {
  return openAppSettings();
}

Future<bool> openLocationSettings() async {
  return Geolocator.openLocationSettings();
}

Future<bool> showPermissionSettingsDialog(
  BuildContext context, {
  required String permissionName,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Izin $permissionName diperlukan'),
            content: Text(
              'Aplikasi membutuhkan izin $permissionName agar fitur ini dapat digunakan. Silakan aktifkan izinnya melalui Pengaturan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await openPermissionSettings();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          );
        },
      ) ??
      false;
}
