import '../entities/child_device.dart';
import '../repositories/offspring_repository.dart';

/// Starts self mode: this phone is used on its own, not linked to a parent.
/// Reuses the existing self-mode device when there is one.
class StartSelfModeUseCase {
  const StartSelfModeUseCase(this._repository);

  final OffspringRepository _repository;

  static const String ownerName = 'Me';
  static const String deviceName = 'This phone';

  Future<ChildDevice> call({String? existingDeviceId}) async {
    if (existingDeviceId != null) {
      final devices = await _repository.getDevices();
      for (final device in devices) {
        if (device.id == existingDeviceId) return device;
      }
    }
    return _repository.createSelfDevice(
      ownerName: ownerName,
      deviceName: deviceName,
    );
  }
}
