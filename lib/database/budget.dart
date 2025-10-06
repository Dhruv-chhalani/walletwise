class Budget {
  final int? id;
  final String category;
  final double amount;
  final String period; // 'monthly' or 'weekly'
  final DateTime createdAt;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    this.period = 'monthly',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Budget to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create Budget from Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      period: map['period'] ?? 'monthly',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
