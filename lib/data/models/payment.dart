class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Payment copyWith({
    String? id,
    String? customerId,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'customerid': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Payment.fromSupabaseMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      customerId: map['customerid'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdat'] as String),
    );
  }
}
