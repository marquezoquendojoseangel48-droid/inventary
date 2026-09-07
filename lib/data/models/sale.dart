class Sale {
  final String id;
  final String? customerId;
  final DateTime date;
  final double subtotal;
  final double total;
  final String? notes;
  final DateTime createdAt;

  Sale({
    required this.id,
    this.customerId,
    required this.date,
    required this.subtotal,
    required this.total,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      customerId: map['customerId'] as String?,
      date: DateTime.parse(map['date'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Sale copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    double? subtotal,
    double? total,
    String? notes,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'customerid': customerId,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
    };
  }

  factory Sale.fromSupabaseMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      customerId: map['customerid'] as String?,
      date: DateTime.parse(map['date'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdat'] as String),
    );
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double total;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      saleId: map['saleId'] as String,
      productId: map['productId'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'saleid': saleId,
      'productid': productId,
      'quantity': quantity,
      'unitprice': unitPrice,
      'total': total,
    };
  }

  factory SaleItem.fromSupabaseMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      saleId: map['saleid'] as String,
      productId: map['productid'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitprice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}
