class ChildDevice {
  const ChildDevice({
    required this.id,
    required this.childName,
    required this.deviceName,
    required this.platform,
    required this.pairingCode,
    required this.isOnline,
    required this.usageAccessEnabled,
    required this.vpnFilterEnabled,
    required this.backgroundServiceRunning,
    required this.protectedModeEnabled,
    required this.lastSyncAt,
    required this.lastOnlineAt,
  });

  final String id;
  final String childName;
  final String deviceName;
  final String platform;
  final String pairingCode;
  final bool isOnline;
  final bool usageAccessEnabled;
  final bool vpnFilterEnabled;
  final bool backgroundServiceRunning;
  final bool protectedModeEnabled;
  final DateTime lastSyncAt;
  final DateTime lastOnlineAt;

  int get enabledProtectionCount {
    return [
      usageAccessEnabled,
      vpnFilterEnabled,
      backgroundServiceRunning,
      protectedModeEnabled,
    ].where((enabled) => enabled).length;
  }

  ChildDevice copyWith({
    String? id,
    String? childName,
    String? deviceName,
    String? platform,
    String? pairingCode,
    bool? isOnline,
    bool? usageAccessEnabled,
    bool? vpnFilterEnabled,
    bool? backgroundServiceRunning,
    bool? protectedModeEnabled,
    DateTime? lastSyncAt,
    DateTime? lastOnlineAt,
  }) {
    return ChildDevice(
      id: id ?? this.id,
      childName: childName ?? this.childName,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      pairingCode: pairingCode ?? this.pairingCode,
      isOnline: isOnline ?? this.isOnline,
      usageAccessEnabled: usageAccessEnabled ?? this.usageAccessEnabled,
      vpnFilterEnabled: vpnFilterEnabled ?? this.vpnFilterEnabled,
      backgroundServiceRunning:
          backgroundServiceRunning ?? this.backgroundServiceRunning,
      protectedModeEnabled: protectedModeEnabled ?? this.protectedModeEnabled,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
    );
  }
}
