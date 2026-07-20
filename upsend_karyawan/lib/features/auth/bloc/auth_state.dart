part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState._({required this.status, this.user, this.errorMessage});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);
  const AuthState.authenticating() : this._(status: AuthStatus.authenticating);
  const AuthState.authenticated(UserModel user)
    : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);
  const AuthState.failure(String message)
    : this._(status: AuthStatus.failure, errorMessage: message);

  @override
  List<Object?> get props => [status, user, errorMessage];
}
