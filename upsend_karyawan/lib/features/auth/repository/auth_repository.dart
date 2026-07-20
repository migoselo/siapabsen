import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const _tokenKey = 'auth_token';

  Future<UserModel> login({required String noHp, required String password}) async {
    final response = await Api.dio.post('/login', data: {
      'no_hp': noHp,
      'password': password,
    });

    final token = response.data['token'] as String;
    final user = UserModel.fromJson(response.data['user']);

    await _saveToken(token);
    Api.dio.options.headers['Authorization'] = 'Bearer $token';

    return user;
  }

  /// Dipanggil saat app dibuka — cek apakah ada sesi login tersimpan & masih valid.
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