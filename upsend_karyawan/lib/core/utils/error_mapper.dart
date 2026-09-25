import 'package:dio/dio.dart';

String mapErrorToMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan Anda dan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid. Silakan coba lagi.';
      case 401:
        return 'Sesi Anda telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses untuk melakukan ini.';
      case 404:
        return 'Data absensi tidak ditemukan. Silakan coba lagi nanti.';
      case 422:
        return 'Data yang dikirim tidak valid.';
      case 500:
      case 502:
      case 503:
        return 'Server sedang bermasalah. Silakan coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}