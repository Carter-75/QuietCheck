class ActivityTrackingRecord {
  final String? id;
  final String userId;
  final DateTime trackingDate;
  final int totalScreenTimeMinutes;
  final int appSwitchCount;
  final double appSwitchVelocity;
  final int focusSessionsCount;
  final int focusDurationMinutes;
  final ActivityPatternType activityPattern;
  final int? batteryLevelStart;
  final int? batteryLevelEnd;
  final DateTime dataCollectionTimestamp;
  final DateTime createdAt;

  ActivityTrackingRecord({
    this.id,
    required this.userId,
    required this.trackingDate,
    required this.totalScreenTimeMinutes,
    required this.appSwitchCount,
    required this.appSwitchVelocity,
    this.focusSessionsCount = 0,
    this.focusDurationMinutes = 0,
    this.activityPattern = ActivityPatternType.idle,
    this.batteryLevelStart,
    this.batteryLevelEnd,
    required this.dataCollectionTimestamp,
    required this.createdAt,
  });

  factory ActivityTrackingRecord.fromJson(Map<String, dynamic> json) {
    return ActivityTrackingRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      trackingDate: DateTime.parse(json['tracking_date'] as String),
      totalScreenTimeMinutes: json['total_screen_time_minutes'] as int,
      appSwitchCount: json['app_switch_count'] as int,
      appSwitchVelocity: (json['app_switch_velocity'] as num).toDouble(),
      focusSessionsCount: json['focus_sessions_count'] as int? ?? 0,
      focusDurationMinutes: json['focus_duration_minutes'] as int? ?? 0,
      activityPattern: _parseActivityPattern(
        json['activity_pattern'] as String?,
      ),
      batteryLevelStart: json['battery_level_start'] as int?,
      batteryLevelEnd: json['battery_level_end'] as int?,
      dataCollectionTimestamp: DateTime.parse(
        json['data_collection_timestamp'] as String,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tracking_date': trackingDate.toIso8601String().split('T')[0],
      'total_screen_time_minutes': totalScreenTimeMinutes,
      'app_switch_count': appSwitchCount,
      'app_switch_velocity': appSwitchVelocity,
      'focus_sessions_count': focusSessionsCount,
      'focus_duration_minutes': focusDurationMinutes,
      'activity_pattern': activityPattern.name,
      if (batteryLevelStart != null) 'battery_level_start': batteryLevelStart,
      if (batteryLevelEnd != null) 'battery_level_end': batteryLevelEnd,
      'data_collection_timestamp': dataCollectionTimestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static ActivityPatternType _parseActivityPattern(String? pattern) {
    switch (pattern) {
      case 'focused':
        return ActivityPatternType.focused;
      case 'distracted':
        return ActivityPatternType.distracted;
      case 'multitasking':
        return ActivityPatternType.multitasking;
      case 'idle':
      default:
        return ActivityPatternType.idle;
    }
  }
}

enum ActivityPatternType { focused, distracted, multitasking, idle }
