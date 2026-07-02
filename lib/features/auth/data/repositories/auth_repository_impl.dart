import '../../domain/entities/parent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  Future<ParentUser?> getCurrentUser() {
    return _localDataSource.getCurrentUser();
  }

  @override
  Future<ParentUser> login({required String email, required String password}) {
    return _localDataSource.login(email: email, password: password);
  }

  @override
  Future<ParentUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _localDataSource.register(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() {
    return _localDataSource.logout();
  }
}
