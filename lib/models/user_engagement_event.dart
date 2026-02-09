class UserEngagementEvent {
  final String? id;
  final String userId;
  final String eventType;
  final String eventName;
  final String? screenName;
  final Map<String, dynamic>? eventProperties;
  final String? sessionId;
  final DateTime eventTimestamp;
  final DateTime createdAt;

  UserEngagementEvent({
    this.id,
    required this.userId,
    required this.eventType,
    required this.eventName,
    this.screenName,
    this.eventProperties,
    this.sessionId,
    required this.eventTimestamp,
    required this.createdAt,
  });

  factory UserEngagementEvent.fromJson(Map<String, dynamic> json) {
    return UserEngagementEvent(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      eventType: json['event_type'] as String,
      eventName: json['event_name'] as String,
      screenName: json['screen_name'] as String?,
      eventProperties: json['event_properties'] as Map<String, dynamic>?,
      sessionId: json['session_id'] as String?,
      eventTimestamp: DateTime.parse(json['event_timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'event_type': eventType,
      'event_name': eventName,
      if (screenName != null) 'screen_name': screenName,
      if (eventProperties != null) 'event_properties': eventProperties,
      if (sessionId != null) 'session_id': sessionId,
      'event_timestamp': eventTimestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
