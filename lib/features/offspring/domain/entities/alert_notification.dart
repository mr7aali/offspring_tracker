enum AlertType {
  appLimit,
  blockedApp,
  blockedWebsite,
  offlineDevice,
  newApp,
  ruleSync,
}

extension AlertTypeLabel on AlertType {
  String get label {
    switch (this) {
      case AlertType.appLimit:
        return 'App limit';
      case AlertType.blockedApp:
        return 'Blocked app';
      case AlertType.blockedWebsite:
        return 'Blocked website';
      case AlertType.offlineDevice:
        return 'Offline device';
      case AlertType.newApp:
        return 'New app';
      case AlertType.ruleSync:
        return 'Rule sync';
    }
  }
}

class AlertNotification {
  const AlertNotification({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String? deviceId;
  final String title;
  final String message;
  final AlertType type;
  final DateTime createdAt;
  final bool isRead;

  AlertNotification copyWith({
    String? id,
    String? deviceId,
    String? title,
    String? message,
    AlertType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AlertNotification(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
