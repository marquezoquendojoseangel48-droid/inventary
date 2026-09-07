class Product {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final double purchasePrice;
  final double salePrice;
  final int minStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.minStock,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= minStock;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'minStock': minStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      quantity: map['quantity'] as int,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      salePrice: (map['salePrice'] as num).toDouble(),
      minStock: map['minStock'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    double? purchasePrice,
    double? salePrice,
    int? minStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'purchaseprice': purchasePrice,
      'saleprice': salePrice,
      'minstock': minStock,
    };
  }

  factory Product.fromSupabaseMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      quantity: map['quantity'] as int,
      purchasePrice: (map['purchaseprice'] as num).toDouble(),
      salePrice: (map['saleprice'] as num).toDouble(),
      minStock: map['minstock'] as int,
      createdAt: DateTime.parse(map['createdat'] as String),
      updatedAt: DateTime.parse(map['updatedat'] as String),
    );
  }
}
