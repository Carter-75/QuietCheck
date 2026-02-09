class AnalyticsRecord {
  final String? id;
  final String userId;
  final DateTime date;
  final double avgMentalLoad;
  final int peakMentalLoad;
  final int dataPointsCollected;
  final double? baselineComparison;
  final int? sleepQuality;
  final String? encryptedNotes;
  final DateTime createdAt;

  AnalyticsRecord({
    this.id,
    required this.userId,
    required this.date,
    required this.avgMentalLoad,
    required this.peakMentalLoad,
    this.dataPointsCollected = 0,
    this.baselineComparison,
    this.sleepQuality,
    this.encryptedNotes,
    required this.createdAt,
  });

  factory AnalyticsRecord.fromJson(Map<String, dynamic> json) {
    return AnalyticsRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      avgMentalLoad: (json['avg_mental_load'] as num).toDouble(),
      peakMentalLoad: json['peak_mental_load'] as int,
      dataPointsCollected: json['data_points_collected'] as int? ?? 0,
      baselineComparison: (json['baseline_comparison'] as num?)?.toDouble(),
      sleepQuality: json['sleep_quality'] as int?,
      encryptedNotes: json['encrypted_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'avg_mental_load': avgMentalLoad,
      'peak_mental_load': peakMentalLoad,
      'data_points_collected': dataPointsCollected,
      if (baselineComparison != null) 'baseline_comparison': baselineComparison,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (encryptedNotes != null) 'encrypted_notes': encryptedNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
