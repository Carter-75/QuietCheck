class GoalMilestone {
  final String? id;
  final String goalId;
  final String userId;
  final String milestoneType;
  final String title;
  final String? description;
  final int achievementValue;
  final DateTime achievedAt;
  final bool celebrated;
  final DateTime createdAt;

  GoalMilestone({
    this.id,
    required this.goalId,
    required this.userId,
    required this.milestoneType,
    required this.title,
    this.description,
    required this.achievementValue,
    required this.achievedAt,
    this.celebrated = false,
    required this.createdAt,
  });

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String?,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      milestoneType: json['milestone_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      achievementValue: json['achievement_value'] as int,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      celebrated: json['celebrated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'milestone_type': milestoneType,
      'title': title,
      if (description != null) 'description': description,
      'achievement_value': achievementValue,
      'achieved_at': achievedAt.toIso8601String(),
      'celebrated': celebrated,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
