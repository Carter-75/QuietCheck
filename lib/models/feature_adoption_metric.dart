class FeatureAdoptionMetric {
  final String? id;
  final String userId;
  final String featureCategory;
  final String featureName;
  final DateTime firstUsedAt;
  final DateTime lastUsedAt;
  final int usageCount;
  final int totalTimeSpentSeconds;
  final bool isActiveUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureAdoptionMetric({
    this.id,
    required this.userId,
    required this.featureCategory,
    required this.featureName,
    required this.firstUsedAt,
    required this.lastUsedAt,
    this.usageCount = 1,
    this.totalTimeSpentSeconds = 0,
    this.isActiveUser = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeatureAdoptionMetric.fromJson(Map<String, dynamic> json) {
    return FeatureAdoptionMetric(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      featureCategory: json['feature_category'] as String,
      featureName: json['feature_name'] as String,
      firstUsedAt: DateTime.parse(json['first_used_at'] as String),
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
      usageCount: json['usage_count'] as int? ?? 1,
      totalTimeSpentSeconds: json['total_time_spent_seconds'] as int? ?? 0,
      isActiveUser: json['is_active_user'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'feature_category': featureCategory,
      'feature_name': featureName,
      'first_used_at': firstUsedAt.toIso8601String(),
      'last_used_at': lastUsedAt.toIso8601String(),
      'usage_count': usageCount,
      'total_time_spent_seconds': totalTimeSpentSeconds,
      'is_active_user': isActiveUser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
