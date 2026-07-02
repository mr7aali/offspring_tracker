import '../entities/parent_user.dart';

abstract class AuthRepository {
  Future<ParentUser?> getCurrentUser();

  Future<ParentUser> login({required String email, required String password});

  Future<ParentUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();
}
