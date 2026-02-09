class RecoverySession {
  final String? id;
  final String userId;
  final String techniqueType;
  final String techniqueTitle;
  final int durationMinutes;
  final bool completed;
  final int elapsedTimeSeconds;
  final DateTime sessionDate;
  final String? encryptedNotes;
  final DateTime createdAt;

  RecoverySession({
    this.id,
    required this.userId,
    required this.techniqueType,
    required this.techniqueTitle,
    required this.durationMinutes,
    this.completed = false,
    this.elapsedTimeSeconds = 0,
    required this.sessionDate,
    this.encryptedNotes,
    required this.createdAt,
  });

  factory RecoverySession.fromJson(Map<String, dynamic> json) {
    return RecoverySession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      techniqueType: json['technique_type'] as String,
      techniqueTitle: json['technique_title'] as String,
      durationMinutes: json['duration_minutes'] as int,
      completed: json['completed'] as bool? ?? false,
      elapsedTimeSeconds: json['elapsed_time_seconds'] as int? ?? 0,
      sessionDate: DateTime.parse(json['session_date'] as String),
      encryptedNotes: json['encrypted_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'technique_type': techniqueType,
      'technique_title': techniqueTitle,
      'duration_minutes': durationMinutes,
      'completed': completed,
      'elapsed_time_seconds': elapsedTimeSeconds,
      'session_date': sessionDate.toIso8601String(),
      if (encryptedNotes != null) 'encrypted_notes': encryptedNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
