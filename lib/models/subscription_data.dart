class SubscriptionData {
  final String? id;
  final String userId;
  final String status;
  final int trialDaysRemaining;
  final DateTime? subscriptionStartDate;
  final DateTime? nextPaymentDate;
  final String? encryptedPaymentInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionData({
    this.id,
    required this.userId,
    this.status = 'trial',
    this.trialDaysRemaining = 7,
    this.subscriptionStartDate,
    this.nextPaymentDate,
    this.encryptedPaymentInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'trial',
      trialDaysRemaining: json['trial_days_remaining'] as int? ?? 7,
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.parse(json['subscription_start_date'] as String)
          : null,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.parse(json['next_payment_date'] as String)
          : null,
      encryptedPaymentInfo: json['encrypted_payment_info'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'status': status,
      'trial_days_remaining': trialDaysRemaining,
      if (subscriptionStartDate != null)
        'subscription_start_date': subscriptionStartDate!.toIso8601String(),
      if (nextPaymentDate != null)
        'next_payment_date': nextPaymentDate!.toIso8601String().split('T')[0],
      if (encryptedPaymentInfo != null)
        'encrypted_payment_info': encryptedPaymentInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isSubscribed => status == 'active';
  bool get isTrial => status == 'trial';
}
