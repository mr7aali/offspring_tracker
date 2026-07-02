import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/parent_user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
  );

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthStatus _status = AuthStatus.unauthenticated;
  ParentUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  ParentUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String password}) {
    return _runAuthAction(
      () => _loginUseCase(email: email, password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => _registerUseCase(name: name, email: email, password: password),
    );
  }

  Future<bool> useDemoAccount() {
    return login(
      email: AppStrings.demoEmail,
      password: AppStrings.demoPassword,
    );
  }

  Future<void> logout() async {
    await _logoutUseCase();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<ParentUser> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
