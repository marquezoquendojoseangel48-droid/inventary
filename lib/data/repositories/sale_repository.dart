import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/sale.dart';
import '../../core/constants/app_constants.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  SaleRepository(this._dbHelper);

  Future<List<Sale>> getAllSales() async {
    final data = await _dbHelper.query(
      AppConstants.salesTable,
      orderBy: 'date DESC',
    );
    return data.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getRecentSales({int limit = 10}) async {
    final data = await _dbHelper.query(
      AppConstants.salesTable,
      orderBy: 'date DESC',
      limit: limit,
    );
    return data.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSaleById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.salesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Sale.fromMap(data.first);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final data = await _dbHelper.query(
      AppConstants.saleItemsTable,
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return data.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<Sale> createSaleWithItems(
    Sale sale,
    List<SaleItem> items,
  ) async {
    return await _dbHelper.executeTransaction((txn) async {
      final newSale = sale.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );

      await txn.insert(
        AppConstants.salesTable,
        newSale.toMap(),
      );

      for (var item in items) {
        final newItem = item.copyWith(
          id: _uuid.v4(),
          saleId: newSale.id,
        );
        await txn.insert(
          AppConstants.saleItemsTable,
          newItem.toMap(),
        );
      }

      return newSale;
    });
  }

  Future<void> deleteSale(String id) async {
    await _dbHelper.executeTransaction((txn) async {
      await txn.delete(
        AppConstants.saleItemsTable,
        where: 'saleId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        AppConstants.salesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
