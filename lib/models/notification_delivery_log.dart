class NotificationDeliveryLog {
  final String? id;
  final String userId;
  final String notificationType;
  final NotificationSeverity severity;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationDeliveryStatus deliveryStatus;
  final int retryCount;
  final DateTime? lastRetryTime;
  final DateTime? deliveredAt;
  final String? failedReason;
  final DateTime? deferredUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationDeliveryLog({
    this.id,
    required this.userId,
    required this.notificationType,
    required this.severity,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.deliveryStatus = NotificationDeliveryStatus.pending,
    this.retryCount = 0,
    this.lastRetryTime,
    this.deliveredAt,
    this.failedReason,
    this.deferredUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationDeliveryLog.fromJson(Map<String, dynamic> json) {
    return NotificationDeliveryLog(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      severity: _parseSeverity(json['severity'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      deliveryStatus: _parseDeliveryStatus(json['delivery_status'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      lastRetryTime: json['last_retry_time'] != null
          ? DateTime.parse(json['last_retry_time'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      failedReason: json['failed_reason'] as String?,
      deferredUntil: json['deferred_until'] != null
          ? DateTime.parse(json['deferred_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'severity': severity.name,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toIso8601String(),
      'delivery_status': deliveryStatus.name,
      'retry_count': retryCount,
      if (lastRetryTime != null)
        'last_retry_time': lastRetryTime!.toIso8601String(),
      if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
      if (failedReason != null) 'failed_reason': failedReason,
      if (deferredUntil != null)
        'deferred_until': deferredUntil!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static NotificationSeverity _parseSeverity(String severity) {
    switch (severity) {
      case 'high':
        return NotificationSeverity.high;
      case 'medium':
        return NotificationSeverity.medium;
      case 'low':
        return NotificationSeverity.low;
      default:
        return NotificationSeverity.medium;
    }
  }

  static NotificationDeliveryStatus _parseDeliveryStatus(String status) {
    switch (status) {
      case 'pending':
        return NotificationDeliveryStatus.pending;
      case 'delivered':
        return NotificationDeliveryStatus.delivered;
      case 'failed':
        return NotificationDeliveryStatus.failed;
      case 'deferred':
        return NotificationDeliveryStatus.deferred;
      default:
        return NotificationDeliveryStatus.pending;
    }
  }
}

enum NotificationSeverity { high, medium, low }

enum NotificationDeliveryStatus { pending, delivered, failed, deferred }
