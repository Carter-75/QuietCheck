class WellnessGoal {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final int targetValue;
  final int currentValue;
  final String unit;
  final String status;
  final DateTime startDate;
  final DateTime targetDate;
  final DateTime? completedAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastProgressDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  WellnessGoal({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    this.unit = 'sessions',
    this.status = 'active',
    required this.startDate,
    required this.targetDate,
    this.completedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastProgressDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WellnessGoal.fromJson(Map<String, dynamic> json) {
    return WellnessGoal(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'sessions',
      status: json['status'] as String? ?? 'active',
      startDate: DateTime.parse(json['start_date'] as String),
      targetDate: DateTime.parse(json['target_date'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastProgressDate: json['last_progress_date'] != null
          ? DateTime.parse(json['last_progress_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      if (lastProgressDate != null)
        'last_progress_date': lastProgressDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue * 100).clamp(0.0, 100.0);
  }

  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && status == 'active';
  }

  WellnessGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    int? targetValue,
    int? currentValue,
    String? unit,
    String? status,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastProgressDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WellnessGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastProgressDate: lastProgressDate ?? this.lastProgressDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
