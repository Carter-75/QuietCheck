class MentalLoadScore {
  final String? id;
  final String userId;
  final int score;
  final String zone;
  final String? encryptedContext;
  final DateTime recordedAt;
  final DateTime createdAt;

  MentalLoadScore({
    this.id,
    required this.userId,
    required this.score,
    required this.zone,
    this.encryptedContext,
    required this.recordedAt,
    required this.createdAt,
  });

  factory MentalLoadScore.fromJson(Map<String, dynamic> json) {
    return MentalLoadScore(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      score: json['score'] as int,
      zone: json['zone'] as String,
      encryptedContext: json['encrypted_context'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'score': score,
      'zone': zone,
      if (encryptedContext != null) 'encrypted_context': encryptedContext,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getZoneLabel() {
    switch (zone) {
      case 'optimal':
        return 'Optimal';
      case 'moderate':
        return 'Moderate';
      case 'elevated':
        return 'Elevated';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }
}
