import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/product.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ProductRepository(this._dbHelper);

  Future<List<Product>> getAllProducts() async {
    final data = await _dbHelper.query(
      AppConstants.productsTable,
      orderBy: 'name ASC',
    );
    return data.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Product.fromMap(data.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _dbHelper.query(
      AppConstants.productsTable,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return data.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final data = await _dbHelper.query(
      AppConstants.productsTable,
      where: 'quantity <= minStock',
      orderBy: 'name ASC',
    );
    return data.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product> createProduct(Product product) async {
    final newProduct = product.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dbHelper.insert(AppConstants.productsTable, newProduct.toMap());
    return newProduct;
  }

  Future<Product> updateProduct(Product product) async {
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );
    await _dbHelper.update(
      AppConstants.productsTable,
      updatedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return updatedProduct;
  }

  Future<void> deleteProduct(String id) async {
    await _dbHelper.delete(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProductQuantity(String productId, int delta) async {
    final product = await getProductById(productId);
    if (product == null) return;

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
