import '../../domain/entities/alert_notification.dart';

class AlertNotificationModel extends AlertNotification {
  const AlertNotificationModel({
    required super.id,
    required super.deviceId,
    required super.title,
    required super.message,
    required super.type,
    required super.createdAt,
    required super.isRead,
  });

  factory AlertNotificationModel.fromEntity(AlertNotification notification) {
    return AlertNotificationModel(
      id: notification.id,
      deviceId: notification.deviceId,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      createdAt: notification.createdAt,
      isRead: notification.isRead,
    );
  }
}
