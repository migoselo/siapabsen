part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dipanggil sekali saat app dibuka (misal di SplashPage) — cek apakah
/// ada sesi login tersimpan (token di SharedPreferences) yang masih valid.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String noHp;
  final String password;

  const AuthLoginRequested({required this.noHp, required this.password});

  @override
  List<Object?> get props => [noHp, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}