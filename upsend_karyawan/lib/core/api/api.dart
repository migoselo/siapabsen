import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static final Dio dio = Dio(
    BaseOptions(
      // baseUrl: 'http://192.168.44.8:8010/api',
      // baseUrl: 'http://siapabsensi.siapsoft.com',
      // baseUrl: 'https://26.214.138.24/api',
      baseUrl: 'https://dipodic-burlily-roxie.ngrok-free.dev/api',
      // baseUrl: 'https://siapabsensi.siapsoft.com/api',

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  static void init() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }

          handler.next(error);
        },
      ),
    );

    // Logging cuma jalan pas debug build, biar keliatan
    // request/response/error persis apa yang dikirim & diterima.
    // Berguna buat ngecek kasus 404 kayak /my-open-session kemarin.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }
}
