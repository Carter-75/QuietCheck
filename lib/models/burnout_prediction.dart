class BurnoutPrediction {
  final String? id;
  final String userId;
  final DateTime predictedThresholdDate;
  final int currentMentalLoadScore;
  final int predictedMentalLoadScore;
  final int hoursUntilThreshold;
  final String confidenceLevel;
  final List<String> identifiedTriggers;
  final List<String> behavioralPatterns;
  final bool warningSent;
  final DateTime? warningSentAt;
  final DateTime predictionTimestamp;
  final DateTime createdAt;

  BurnoutPrediction({
    this.id,
    required this.userId,
    required this.predictedThresholdDate,
    required this.currentMentalLoadScore,
    required this.predictedMentalLoadScore,
    required this.hoursUntilThreshold,
    required this.confidenceLevel,
    required this.identifiedTriggers,
    required this.behavioralPatterns,
    this.warningSent = false,
    this.warningSentAt,
    required this.predictionTimestamp,
    required this.createdAt,
  });

  factory BurnoutPrediction.fromJson(Map<String, dynamic> json) {
    return BurnoutPrediction(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      predictedThresholdDate: DateTime.parse(
        json['predicted_threshold_date'] as String,
      ),
      currentMentalLoadScore: json['current_mental_load_score'] as int,
      predictedMentalLoadScore: json['predicted_mental_load_score'] as int,
      hoursUntilThreshold: json['hours_until_threshold'] as int,
      confidenceLevel: json['confidence_level'] as String,
      identifiedTriggers:
          (json['identified_triggers'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      behavioralPatterns:
          (json['behavioral_patterns'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      warningSent: json['warning_sent'] as bool? ?? false,
      warningSentAt: json['warning_sent_at'] != null
          ? DateTime.parse(json['warning_sent_at'] as String)
          : null,
      predictionTimestamp: DateTime.parse(
        json['prediction_timestamp'] as String,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'predicted_threshold_date': predictedThresholdDate.toIso8601String(),
      'current_mental_load_score': currentMentalLoadScore,
      'predicted_mental_load_score': predictedMentalLoadScore,
      'hours_until_threshold': hoursUntilThreshold,
      'confidence_level': confidenceLevel,
      'identified_triggers': identifiedTriggers,
      'behavioral_patterns': behavioralPatterns,
      'warning_sent': warningSent,
      if (warningSentAt != null)
        'warning_sent_at': warningSentAt!.toIso8601String(),
      'prediction_timestamp': predictionTimestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getSeverityLevel() {
    if (hoursUntilThreshold <= 24) return 'high';
    if (hoursUntilThreshold <= 36) return 'medium';
    return 'low';
  }
}
