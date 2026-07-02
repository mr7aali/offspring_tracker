import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../models/parent_user_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource() {
    final demoUser = ParentUserModel(
      id: 'parent-demo',
      name: 'Avery Brooks',
      email: AppStrings.demoEmail,
      planName: 'Premium',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );
    _usersByEmail[demoUser.email] = demoUser;
    _passwordsByEmail[demoUser.email] = AppStrings.demoPassword;
  }

  final Map<String, ParentUserModel> _usersByEmail = {};
  final Map<String, String> _passwordsByEmail = {};
  ParentUserModel? _currentUser;

  Future<ParentUserModel?> getCurrentUser() async {
    return _currentUser;
  }

  Future<ParentUserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];
    if (user == null || _passwordsByEmail[normalizedEmail] != password) {
      throw const AppFailure('Email or password is incorrect');
    }
    _currentUser = user;
    return user;
  }

  Future<ParentUserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      throw const AppFailure('An account already exists for this email');
    }

    final user = ParentUserModel(
      id: 'parent-${_usersByEmail.length + 1}',
      name: name.trim(),
      email: normalizedEmail,
      planName: 'Free',
      createdAt: DateTime.now(),
    );
    _usersByEmail[normalizedEmail] = user;
    _passwordsByEmail[normalizedEmail] = password;
    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}
