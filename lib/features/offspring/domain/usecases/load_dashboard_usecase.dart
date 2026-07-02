import '../entities/admin_snapshot.dart';
import '../entities/alert_notification.dart';
import '../entities/child_device.dart';
import '../entities/dashboard_summary.dart';
import '../entities/subscription_plan.dart';
import '../entities/tracked_app.dart';
import '../entities/website_rule.dart';
import '../repositories/offspring_repository.dart';

class DashboardData {
  const DashboardData({
    required this.devices,
    required this.selectedDevice,
    required this.apps,
    required this.websiteRules,
    required this.notifications,
    required this.summary,
    required this.adminSnapshot,
    required this.subscriptionPlans,
  });

  final List<ChildDevice> devices;
  final ChildDevice? selectedDevice;
  final List<TrackedApp> apps;
  final List<WebsiteRule> websiteRules;
  final List<AlertNotification> notifications;
  final DashboardSummary summary;
  final AdminSnapshot adminSnapshot;
  final List<SubscriptionPlan> subscriptionPlans;
}

class LoadDashboardUseCase {
  const LoadDashboardUseCase(this._repository);

  final OffspringRepository _repository;

  Future<DashboardData> call({String? selectedDeviceId}) async {
    final devices = await _repository.getDevices();
    final selectedDevice = _selectDevice(devices, selectedDeviceId);
    final apps = selectedDevice == null
        ? <TrackedApp>[]
        : await _repository.getApps(selectedDevice.id);
    final websiteRules = selectedDevice == null
        ? <WebsiteRule>[]
        : await _repository.getWebsiteRules(selectedDevice.id);

    return DashboardData(
      devices: devices,
      selectedDevice: selectedDevice,
      apps: apps,
      websiteRules: websiteRules,
      notifications: await _repository.getNotifications(),
      summary: await _repository.getSummary(),
      adminSnapshot: await _repository.getAdminSnapshot(),
      subscriptionPlans: await _repository.getSubscriptionPlans(),
    );
  }

  ChildDevice? _selectDevice(
    List<ChildDevice> devices,
    String? selectedDeviceId,
  ) {
    if (devices.isEmpty) {
      return null;
    }
    if (selectedDeviceId == null) {
      return devices.first;
    }
    for (final device in devices) {
      if (device.id == selectedDeviceId) {
        return device;
      }
    }
    return devices.first;
  }
}
