class Customer {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  double pendingBalance;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.pendingBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pendingBalance': pendingBalance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      pendingBalance: (map['pendingBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? pendingBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
      'phone': phone,
      'pendingbalance': pendingBalance,
    };
  }

  factory Customer.fromSupabaseMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['createdat'] as String),
      updatedAt: DateTime.parse(map['updatedat'] as String),
      pendingBalance: (map['pendingbalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
