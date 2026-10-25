import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/usecases/connect_child_device_usecase.dart';
import '../../domain/usecases/start_self_mode_usecase.dart';

enum ChildSessionStatus { signedOut, signedIn }

/// How the child dashboard session was started.
enum ChildSessionMode {
  /// This phone is used on its own, not linked to a parent.
  self,

  /// This phone is linked to a parent with a pairing code.
  paired,
}

class ChildSessionController extends ChangeNotifier {
  ChildSessionController(
    this._connectChildDeviceUseCase,
    this._startSelfModeUseCase,
  );

  final ConnectChildDeviceUseCase _connectChildDeviceUseCase;
  final StartSelfModeUseCase _startSelfModeUseCase;

  ChildSessionStatus _status = ChildSessionStatus.signedOut;
  ChildSessionMode? _mode;
  ChildDevice? _currentDevice;
  String? _selfDeviceId;
  bool _isLoading = false;
  String? _errorMessage;

  ChildSessionStatus get status => _status;
  ChildSessionMode? get mode => _mode;
  bool get isSelfMode => _mode == ChildSessionMode.self;
  ChildDevice? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> startSelfMode() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final device = await _startSelfModeUseCase(
        existingDeviceId: _selfDeviceId,
      );
      _selfDeviceId = device.id;
      _currentDevice = device;
      _mode = ChildSessionMode.self;
      _status = ChildSessionStatus.signedIn;
      return true;
    } catch (_) {
      _errorMessage = 'Unable to start self mode. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connect({required String pairingCode}) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDevice = await _connectChildDeviceUseCase(
        pairingCode: pairingCode,
      );
      _mode = ChildSessionMode.paired;
      _status = ChildSessionStatus.signedIn;
      return true;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to connect this device. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentDevice = null;
    _mode = null;
    _status = ChildSessionStatus.signedOut;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
