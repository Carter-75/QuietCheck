class AppUsageRecord {
  final String? id;
  final String userId;
  final DateTime trackingDate;
  final String appPackageName;
  final String? appName;
  final int usageDurationMinutes;
  final int openCount;
  final DateTime? lastUsedTimestamp;
  final DateTime createdAt;

  AppUsageRecord({
    this.id,
    required this.userId,
    required this.trackingDate,
    required this.appPackageName,
    this.appName,
    required this.usageDurationMinutes,
    this.openCount = 0,
    this.lastUsedTimestamp,
    required this.createdAt,
  });

  factory AppUsageRecord.fromJson(Map<String, dynamic> json) {
    return AppUsageRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      trackingDate: DateTime.parse(json['tracking_date'] as String),
      appPackageName: json['app_package_name'] as String,
      appName: json['app_name'] as String?,
      usageDurationMinutes: json['usage_duration_minutes'] as int,
      openCount: json['open_count'] as int? ?? 0,
      lastUsedTimestamp: json['last_used_timestamp'] != null
          ? DateTime.parse(json['last_used_timestamp'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tracking_date': trackingDate.toIso8601String().split('T')[0],
      'app_package_name': appPackageName,
      if (appName != null) 'app_name': appName,
      'usage_duration_minutes': usageDurationMinutes,
      'open_count': openCount,
      if (lastUsedTimestamp != null)
        'last_used_timestamp': lastUsedTimestamp!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
