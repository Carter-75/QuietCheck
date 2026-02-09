class UserSettings {
  final String? id;
  final String userId;
  final double sensitivityValue;
  final String selectedSoundPack;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool highSeverityNotifications;
  final bool mediumSeverityNotifications;
  final bool lowSeverityNotifications;
  final bool vibrationEnabled;
  final String? encryptedPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    this.id,
    required this.userId,
    this.sensitivityValue = 50.0,
    this.selectedSoundPack = 'Calming Waves',
    this.quietHoursStart = '22:00:00',
    this.quietHoursEnd = '07:00:00',
    this.highSeverityNotifications = true,
    this.mediumSeverityNotifications = true,
    this.lowSeverityNotifications = false,
    this.vibrationEnabled = true,
    this.encryptedPreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      sensitivityValue: (json['sensitivity_value'] as num?)?.toDouble() ?? 50.0,
      selectedSoundPack:
          json['selected_sound_pack'] as String? ?? 'Calming Waves',
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00:00',
      highSeverityNotifications:
          json['high_severity_notifications'] as bool? ?? true,
      mediumSeverityNotifications:
          json['medium_severity_notifications'] as bool? ?? true,
      lowSeverityNotifications:
          json['low_severity_notifications'] as bool? ?? false,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      encryptedPreferences: json['encrypted_preferences'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sensitivity_value': sensitivityValue,
      'selected_sound_pack': selectedSoundPack,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'high_severity_notifications': highSeverityNotifications,
      'medium_severity_notifications': mediumSeverityNotifications,
      'low_severity_notifications': lowSeverityNotifications,
      'vibration_enabled': vibrationEnabled,
      if (encryptedPreferences != null)
        'encrypted_preferences': encryptedPreferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
