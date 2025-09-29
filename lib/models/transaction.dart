class Transaction {
  final int? id;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String? note;
  final DateTime date;
  final String status; // 'completed' or 'pending'

  Transaction({
    this.id,
    required this.amount,
    required this.category,
    required this.type,
    this.note,
    required this.date,
    this.status = 'completed',
  });

  // Convert Transaction to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'type': type,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'status': status,
    };
  }

  // Create Transaction from Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      type: map['type'],
      note: map['note'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      status: map['status'] ?? 'completed',
    );
  }
}
