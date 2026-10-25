import '../repositories/device_protection.dart';
import '../repositories/offspring_repository.dart';

/// Copies real screen time from the phone into the device's app list.
class RefreshAppUsageUseCase {
  const RefreshAppUsageUseCase(this._protection, this._repository);

  final DeviceProtection _protection;
  final OffspringRepository _repository;

  /// Does nothing when usage access is not allowed.
  Future<void> call(String deviceId) async {
    final status = await _protection.status();
    if (!status.usageAccessGranted) return;
    final usage = await _protection.usage();
    await _repository.updateAppUsage(deviceId, usage);
  }
}
