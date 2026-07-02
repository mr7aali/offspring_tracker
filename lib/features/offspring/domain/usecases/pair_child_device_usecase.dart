import '../entities/child_device.dart';
import '../repositories/offspring_repository.dart';

class PairChildDeviceUseCase {
  const PairChildDeviceUseCase(this._repository);

  final OffspringRepository _repository;

  Future<ChildDevice> call({
    required String childName,
    required String deviceName,
    required String pairingCode,
  }) {
    return _repository.pairDevice(
      childName: childName,
      deviceName: deviceName,
      pairingCode: pairingCode,
    );
  }
}
