class Purchase {
  final String id;
  final String supplierId;
  final DateTime date;
  final double total;
  final String? notes;
  final DateTime createdAt;

  Purchase({
    required this.id,
    required this.supplierId,
    required this.date,
    required this.total,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'date': date.toIso8601String(),
      'total': total,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      supplierId: map['supplierId'] as String,
      date: DateTime.parse(map['date'] as String),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Purchase copyWith({
    String? id,
    String? supplierId,
    DateTime? date,
    double? total,
    String? notes,
    DateTime? createdAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      date: date ?? this.date,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'supplierid': supplierId,
      'date': date.toIso8601String(),
      'total': total,
      'notes': notes,
    };
  }

  factory Purchase.fromSupabaseMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      supplierId: map['supplierid'] as String,
      date: DateTime.parse(map['date'] as String),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdat'] as String),
    );
  }
}

class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double total;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as String,
      purchaseId: map['purchaseId'] as String,
      productId: map['productId'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  PurchaseItem copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'purchaseid': purchaseId,
      'productid': productId,
      'quantity': quantity,
      'unitprice': unitPrice,
      'total': total,
    };
  }

  factory PurchaseItem.fromSupabaseMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as String,
      purchaseId: map['purchaseid'] as String,
      productId: map['productid'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitprice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}
