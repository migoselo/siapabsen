import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AttendanceSchedule {
  const AttendanceSchedule({
    required this.startTime,
    required this.endTime,
    required this.lateToleranceMinutes,
    required this.radiusMeters,
  });

  final DateTime startTime;
  final DateTime endTime;
  final int lateToleranceMinutes;
  final int radiusMeters;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _attendanceChannel =
      AndroidNotificationChannel(
        'attendance_radius',
        'Pengingat Absensi',
        description: 'Notifikasi absensi, shift, dan lokasi kerja.',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        'general_notifications',
        'Notifikasi Umum',
        description: 'Notifikasi umum seperti cuti, izin, dan jadwal.',
        importance: Importance.defaultImportance,
      );

  Future<void> initialize({bool requestPermission = true}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    await _plugin.cancel(2001);

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(_attendanceChannel);
    await androidImplementation?.createNotificationChannel(_generalChannel);

    if (requestPermission) {
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  AttendanceSchedule resolveSchedule({
    DateTime? shiftStart,
    DateTime? shiftEnd,
    int? shiftLateToleranceMinutes,
    int? shiftRadiusMeters,
    DateTime? officeStart,
    DateTime? officeEnd,
    int? officeLateToleranceMinutes,
    int? officeRadiusMeters,
    int defaultLateToleranceMinutes = 15,
    int defaultRadiusMeters = 100,
  }) {
    final effectiveStart = shiftStart ?? officeStart;
    final effectiveEnd = shiftEnd ?? officeEnd;

    final lateTolerance =
        shiftLateToleranceMinutes ??
        officeLateToleranceMinutes ??
        defaultLateToleranceMinutes;

    final radius =
        shiftRadiusMeters ?? officeRadiusMeters ?? defaultRadiusMeters;

    if (effectiveStart == null || effectiveEnd == null) {
      final now = DateTime.now();
      return AttendanceSchedule(
        startTime: DateTime(now.year, now.month, now.day, 8, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 0),
        lateToleranceMinutes: lateTolerance,
        radiusMeters: radius,
      );
    }

    return AttendanceSchedule(
      startTime: effectiveStart,
      endTime: effectiveEnd,
      lateToleranceMinutes: lateTolerance,
      radiusMeters: radius,
    );
  }

  Future<void> showCheckInReminder({required String message}) {
    return _show(
      101,
      'Reminder Check-in',
      message,
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showCheckOutReminder({required String message}) {
    return _show(
      102,
      'Reminder Checkout',
      message,
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showLateNotice({required int minutesLate}) {
    return _show(
      103,
      'Terlambat',
      'Anda terlambat $minutesLate menit. Mohon perhatikan ketepatan waktu.',
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showAbsentNotice({required String message}) {
    return _show(104, 'Belum Absen', message, channelId: _attendanceChannel.id);
  }

  Future<void> showForgotCheckout({required String message}) {
    return _show(
      105,
      'Lupa Checkout',
      message,
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showOutsideRadius({required int distanceMeters}) {
    return _show(
      1001,
      'Pengingat checkout',
      'Anda berada di luar radius absensi ($distanceMeters m). Jangan lupa checkout.',
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showLocationUnavailable({required String message}) {
    return _show(
      106,
      'Lokasi tidak tersedia',
      message,
      channelId: _attendanceChannel.id,
    );
  }

  Future<void> showFaceRegistrationNeeded() {
    return _show(
      107,
      'Registrasi Wajah',
      'Wajah Anda belum terdaftar. Daftarkan wajah untuk bisa melakukan absensi.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showFaceVerificationFailed() {
    return _show(
      108,
      'Verifikasi Wajah Gagal',
      'Verifikasi wajah gagal. Silakan coba lagi.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showLeaveStatus({required String status}) {
    return _show(
      109,
      'Status Cuti/Izin',
      'Pengajuan Anda saat ini: $status.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showLeaveRequestSubmitted({required String type}) {
    final label = _normalizeLeaveLabel(type);
    return _show(
      109,
      'Pengajuan $label Terkirim',
      'Pengajuan $label Anda telah berhasil dikirim dan sedang diproses.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showLeaveRequestPending({required String type}) {
    final label = _normalizeLeaveLabel(type);
    return _show(
      110,
      'Pengajuan $label Menunggu Persetujuan',
      'Pengajuan $label Anda sedang menunggu persetujuan.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showLeaveRequestApproved({required String type}) {
    final label = _normalizeLeaveLabel(type);
    return _show(
      111,
      'Pengajuan $label Disetujui',
      'Pengajuan $label Anda telah disetujui.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showLeaveRequestRejected({
    required String type,
    String? reason,
  }) {
    final label = _normalizeLeaveLabel(type);
    final details = reason != null && reason.trim().isNotEmpty
        ? ' Alasan: $reason.'
        : '';

    return _show(
      112,
      'Pengajuan $label Ditolak',
      'Pengajuan $label Anda ditolak.$details',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showOvertimeRequestSubmitted() {
    return _show(
      113,
      'Pengajuan Lembur Terkirim',
      'Pengajuan lembur Anda telah berhasil dikirim dan sedang diproses.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showOvertimeRequestApproved() {
    return _show(
      114,
      'Pengajuan Lembur Disetujui',
      'Pengajuan lembur Anda telah disetujui.',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showOvertimeRequestRejected({String? reason}) {
    final details = reason != null && reason.trim().isNotEmpty
        ? ' Alasan: $reason.'
        : '';

    return _show(
      115,
      'Pengajuan Lembur Ditolak',
      'Pengajuan lembur Anda ditolak.$details',
      channelId: _generalChannel.id,
    );
  }

  Future<void> showShiftChanged({required String message}) {
    return _show(
      116,
      'Jadwal Shift Berubah',
      message,
      channelId: _generalChannel.id,
    );
  }

  Future<void> showOfficeFallback({required String message}) {
    return _show(
      117,
      'Jam Kantor Dipakai',
      message,
      channelId: _generalChannel.id,
    );
  }

  Future<void> showAdminAlert({
    required String title,
    required String message,
  }) {
    return _show(118, title, message, channelId: _generalChannel.id);
  }

  String _normalizeLeaveLabel(String type) {
    final normalized = type.trim();
    if (normalized.toLowerCase() == 'izin') return 'Izin';
    if (normalized.toLowerCase() == 'lembur') return 'Lembur';
    if (normalized.toLowerCase() == 'cuti') return 'Cuti';
    return normalized.isNotEmpty ? normalized : 'Permohonan';
  }

  Future<void> _show(
    int id,
    String title,
    String body, {
    required String channelId,
  }) {
    return _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _attendanceChannel.id
              ? _attendanceChannel.name
              : _generalChannel.name,
          channelDescription: channelId == _attendanceChannel.id
              ? _attendanceChannel.description
              : _generalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_foreground',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
