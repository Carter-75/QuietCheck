class BillingHistory {
  final String? id;
  final String userId;
  final DateTime transactionDate;
  final String amount;
  final String status;
  final String? encryptedReceiptUrl;
  final DateTime createdAt;

  BillingHistory({
    this.id,
    required this.userId,
    required this.transactionDate,
    required this.amount,
    this.status = 'Completed',
    this.encryptedReceiptUrl,
    required this.createdAt,
  });

  factory BillingHistory.fromJson(Map<String, dynamic> json) {
    return BillingHistory(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      amount: json['amount'] as String,
      status: json['status'] as String? ?? 'Completed',
      encryptedReceiptUrl: json['encrypted_receipt_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'amount': amount,
      'status': status,
      if (encryptedReceiptUrl != null)
        'encrypted_receipt_url': encryptedReceiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
