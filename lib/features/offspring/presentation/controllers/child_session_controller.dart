import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/usecases/login_child_device_usecase.dart';

enum ChildSessionStatus { signedOut, signedIn }

class ChildSessionController extends ChangeNotifier {
  ChildSessionController(this._loginChildDeviceUseCase);

  final LoginChildDeviceUseCase _loginChildDeviceUseCase;

  ChildSessionStatus _status = ChildSessionStatus.signedOut;
  ChildDevice? _currentDevice;
  bool _isLoading = false;
  String? _errorMessage;

  ChildSessionStatus get status => _status;
  ChildDevice? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String childIdentifier,
    required String pairingCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDevice = await _loginChildDeviceUseCase(
        childIdentifier: childIdentifier,
        pairingCode: pairingCode,
      );
      _status = ChildSessionStatus.signedIn;
      return true;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in child device.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentDevice = null;
    _status = ChildSessionStatus.signedOut;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
