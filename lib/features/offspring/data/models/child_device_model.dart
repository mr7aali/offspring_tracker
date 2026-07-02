import '../../domain/entities/child_device.dart';

class ChildDeviceModel extends ChildDevice {
  const ChildDeviceModel({
    required super.id,
    required super.childName,
    required super.deviceName,
    required super.platform,
    required super.pairingCode,
    required super.isOnline,
    required super.usageAccessEnabled,
    required super.vpnFilterEnabled,
    required super.backgroundServiceRunning,
    required super.protectedModeEnabled,
    required super.lastSyncAt,
    required super.lastOnlineAt,
  });

  factory ChildDeviceModel.fromEntity(ChildDevice device) {
    return ChildDeviceModel(
      id: device.id,
      childName: device.childName,
      deviceName: device.deviceName,
      platform: device.platform,
      pairingCode: device.pairingCode,
      isOnline: device.isOnline,
      usageAccessEnabled: device.usageAccessEnabled,
      vpnFilterEnabled: device.vpnFilterEnabled,
      backgroundServiceRunning: device.backgroundServiceRunning,
      protectedModeEnabled: device.protectedModeEnabled,
      lastSyncAt: device.lastSyncAt,
      lastOnlineAt: device.lastOnlineAt,
    );
  }
}
