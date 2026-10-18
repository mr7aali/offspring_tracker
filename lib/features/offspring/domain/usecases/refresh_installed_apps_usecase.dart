import '../repositories/installed_apps_source.dart';
import '../repositories/offspring_repository.dart';

class RefreshInstalledAppsUseCase {
  const RefreshInstalledAppsUseCase(this.source, this._repository);

  final InstalledAppsSource source;
  final OffspringRepository _repository;

  Future<void> call(String deviceId) async {
    if (!source.isSupported) return;
    final apps = await source.discover();
    await _repository.syncInstalledApps(deviceId, apps);
  }
}
