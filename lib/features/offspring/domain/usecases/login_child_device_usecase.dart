import '../../../../core/errors/failures.dart';
import '../entities/child_device.dart';
import '../repositories/offspring_repository.dart';

class LoginChildDeviceUseCase {
  const LoginChildDeviceUseCase(this._repository);

  final OffspringRepository _repository;

  Future<ChildDevice> call({
    required String childIdentifier,
    required String pairingCode,
  }) async {
    final normalizedIdentifier = childIdentifier.trim().toLowerCase();
    final normalizedCode = pairingCode.trim().toUpperCase();

    if (normalizedIdentifier.isEmpty || normalizedCode.isEmpty) {
      throw const AppFailure('Child name and pairing code are required');
    }

    final devices = await _repository.getDevices();
    for (final device in devices) {
      final childName = device.childName.trim().toLowerCase();
      final deviceName = device.deviceName.trim().toLowerCase();
      final code = device.pairingCode.trim().toUpperCase();
      final matchesIdentifier =
          childName == normalizedIdentifier ||
          deviceName == normalizedIdentifier;

      if (matchesIdentifier && code == normalizedCode) {
        return device;
      }
    }

    throw const AppFailure('Child name/device or pairing code is incorrect');
  }
}
