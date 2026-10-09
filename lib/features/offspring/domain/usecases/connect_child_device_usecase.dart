import '../../../../core/errors/failures.dart';
import '../entities/child_device.dart';
import '../repositories/offspring_repository.dart';

class ConnectChildDeviceUseCase {
  const ConnectChildDeviceUseCase(this._repository);

  final OffspringRepository _repository;

  Future<ChildDevice> call({required String pairingCode}) async {
    final normalizedCode = pairingCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw const AppFailure('A pairing code is required');
    }

    final devices = await _repository.getDevices();
    for (final device in devices) {
      if (device.pairingCode.trim().toUpperCase() == normalizedCode) {
        return device;
      }
    }

    throw const AppFailure(
      'Pairing code not found. Check the code on the parent dashboard.',
    );
  }
}
