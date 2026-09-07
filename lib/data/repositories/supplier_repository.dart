import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/supplier.dart';
import '../../core/constants/app_constants.dart';

class SupplierRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  SupplierRepository(this._dbHelper);

  Future<List<Supplier>> getAllSuppliers() async {
    final data = await _dbHelper.query(
      AppConstants.suppliersTable,
      orderBy: 'name ASC',
    );
    return data.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.suppliersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Supplier.fromMap(data.first);
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final data = await _dbHelper.query(
      AppConstants.suppliersTable,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return data.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final newSupplier = supplier.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dbHelper.insert(AppConstants.suppliersTable, newSupplier.toMap());
    return newSupplier;
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    final updatedSupplier = supplier.copyWith(
      updatedAt: DateTime.now(),
    );
    await _dbHelper.update(
      AppConstants.suppliersTable,
      updatedSupplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
    return updatedSupplier;
  }

  Future<void> deleteSupplier(String id) async {
    await _dbHelper.delete(
      AppConstants.suppliersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
