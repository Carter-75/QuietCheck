class GoalAiRecommendation {
  final String? id;
  final String userId;
  final String? goalId;
  final String recommendationText;
  final String? reasoning;
  final int priority;
  final bool applied;
  final bool dismissed;
  final DateTime generatedAt;
  final DateTime createdAt;

  GoalAiRecommendation({
    this.id,
    required this.userId,
    this.goalId,
    required this.recommendationText,
    this.reasoning,
    this.priority = 1,
    this.applied = false,
    this.dismissed = false,
    required this.generatedAt,
    required this.createdAt,
  });

  factory GoalAiRecommendation.fromJson(Map<String, dynamic> json) {
    return GoalAiRecommendation(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String?,
      recommendationText: json['recommendation_text'] as String,
      reasoning: json['reasoning'] as String?,
      priority: json['priority'] as int? ?? 1,
      applied: json['applied'] as bool? ?? false,
      dismissed: json['dismissed'] as bool? ?? false,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (goalId != null) 'goal_id': goalId,
      'recommendation_text': recommendationText,
      if (reasoning != null) 'reasoning': reasoning,
      'priority': priority,
      'applied': applied,
      'dismissed': dismissed,
      'generated_at': generatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
