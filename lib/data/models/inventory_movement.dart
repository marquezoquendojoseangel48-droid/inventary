enum MovementType {
  purchase,
  sale,
  payment,
  inventoryAdjustment,
  productCreated,
}

class InventoryMovement {
  final String id;
  final MovementType type;
  final String description;
  final DateTime date;
  final double? amount;
  final String? relatedId;
  final DateTime createdAt;

  InventoryMovement({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    this.amount,
    this.relatedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as String,
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.inventoryAdjustment,
      ),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num?)?.toDouble(),
      relatedId: map['relatedId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  InventoryMovement copyWith({
    String? id,
    MovementType? type,
    String? description,
    DateTime? date,
    double? amount,
    String? relatedId,
    DateTime? createdAt,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case MovementType.purchase:
        return 'Compra';
      case MovementType.sale:
        return 'Venta';
      case MovementType.payment:
        return 'Pago';
      case MovementType.inventoryAdjustment:
        return 'Ajuste Inventario';
      case MovementType.productCreated:
        return 'Producto Creado';
    }
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'relatedid': relatedId,
    };
  }

  factory InventoryMovement.fromSupabaseMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as String,
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.inventoryAdjustment,
      ),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num?)?.toDouble(),
      relatedId: map['relatedid'] as String?,
      createdAt: DateTime.parse(map['createdat'] as String),
    );
  }
}
