import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class ProductRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  ProductRepositorySupabase(this._supabaseService);

  Future<List<Product>> getAllProducts() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Product.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Product?> getProductById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .select()
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Product.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .select()
        .order('name', ascending: true);

    final products = (response as List)
        .map((map) => Product.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();

    // Filtrar localmente productos con stock bajo
    return products.where((p) => p.isLowStock).toList();
  }

  Future<Product> createProduct(Product product) async {
    final newProduct = product.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .insert(newProduct.toSupabaseMap());

    return newProduct;
  }

  Future<Product> updateProduct(Product product) async {
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .update(updatedProduct.toSupabaseMap())
        .eq('id', product.id);

    return updatedProduct;
  }

  Future<void> deleteProduct(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.productsTable)
        .delete()
        .eq('id', id);
  }

  Future<void> updateProductQuantity(String productId, int delta) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Producto no encontrado');
    }

    final newQuantity = product.quantity + delta;
    if (newQuantity < 0) {
      throw Exception('No se permite inventario negativo');
    }

    await updateProduct(product.copyWith(quantity: newQuantity));
  }

  Future<double> getTotalInventoryValue() async {
    final products = await getAllProducts();
    return products.fold<double>(
      0.0,
      (sum, product) => sum + (product.quantity * product.purchasePrice),
    );
  }

  Future<int> getTotalProductCount() async {
    final products = await getAllProducts();
    return products.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
  }
}
