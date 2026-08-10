import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const _tokenKey = 'auth_token';

  Future<UserModel> login({required String noHp, required String password}) async {
    try {
      final response = await Api.dio.post('/login', data: {
        'no_hp': noHp,
        'password': password,
      });

      final token = response.data['token'] as String;
      final user = UserModel.fromJson(response.data['user']);

      await _saveToken(token);
      Api.dio.options.headers['Authorization'] = 'Bearer $token';

      return user;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data['errors'] != null) {
          final firstError = (data['errors'] as Map).values.first[0];
          throw Exception(firstError.toString());
        }
        if (data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      }
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) return null;

    Api.dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await Api.dio.get('/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      await _clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await Api.dio.post('/logout');
    } catch (_) {
      // Tetap clear token lokal walau request logout ke server gagal
    }
    await _clearToken();
  }

  // =====================================================================
  // BELUM DIKONFIRMASI — endpoint & nama field di bawah ini ASUMSI,
  // gak ada di AuthController.php yang pernah kamu kasih (cuma ada
  // register/login/logout/me). Perlu ditambahin dulu di backend,
  // atau disesuaikan namanya kalau ternyata udah ada dengan nama beda.
  // =====================================================================
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await Api.dio.post('/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data['errors'] != null) {
          final firstError = (data['errors'] as Map).values.first[0];
          throw Exception(firstError.toString());
        }
        if (data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      }
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}