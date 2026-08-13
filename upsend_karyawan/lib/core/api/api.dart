import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://dipodic-burlily-roxie.ngrok-free.dev/api',
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
