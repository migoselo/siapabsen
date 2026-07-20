import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const _tokenKey = 'auth_token';

  Future<UserModel> login({
    required String noHp,
    required String password,
  }) async {
    final response = await Api.dio.post(
      '/login',
      data: {'no_hp': noHp, 'password': password},
    );

    // Backend bisa balikin key 'token' ATAU 'access_token'.
    final token = response.data['token'] ?? response.data['access_token'];
    if (token == null) {
      throw Exception('Token tidak ditemukan dari respon server.');
    }

    final rawUser = response.data['user'];
    if (rawUser == null) {
      throw Exception('Data user tidak ditemukan dari respon server.');
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(rawUser));

    await _saveToken(token.toString());
    Api.dio.options.headers['Authorization'] = 'Bearer $token';

    // Simpan juga nama ke cache lokal biar konsisten dengan getCurrentUser().
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user.name);

    return user;
  }

  /// Dipanggil saat app dibuka — cek apakah ada sesi login tersimpan & masih valid.
  Future<UserModel?> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) return null;

    Api.dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await Api.dio.get('/me');

      final rawData = response.data;
      final Map<String, dynamic> userJson =
          (rawData is Map && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);

      final user = UserModel.fromJson(userJson);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', user.name);

      return user;
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
