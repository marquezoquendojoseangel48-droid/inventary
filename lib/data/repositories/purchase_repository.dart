import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/purchase.dart';
import '../../core/constants/app_constants.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  PurchaseRepository(this._dbHelper);

  Future<List<Purchase>> getAllPurchases() async {
    final data = await _dbHelper.query(
      AppConstants.purchasesTable,
      orderBy: 'date DESC',
    );
    return data.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<Purchase?> getPurchaseById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.purchasesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Purchase.fromMap(data.first);
  }

  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    final data = await _dbHelper.query(
      AppConstants.purchaseItemsTable,
      where: 'purchaseId = ?',
      whereArgs: [purchaseId],
    );
    return data.map((map) => PurchaseItem.fromMap(map)).toList();
  }

  Future<Purchase> createPurchaseWithItems(
    Purchase purchase,
    List<PurchaseItem> items,
  ) async {
    return await _dbHelper.executeTransaction((txn) async {
      final newPurchase = purchase.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );

      await txn.insert(
        AppConstants.purchasesTable,
        newPurchase.toMap(),
      );

      for (var item in items) {
        final newItem = item.copyWith(
          id: _uuid.v4(),
          purchaseId: newPurchase.id,
        );
        await txn.insert(
          AppConstants.purchaseItemsTable,
          newItem.toMap(),
        );
      }

      return newPurchase;
    });
  }

  Future<void> deletePurchase(String id) async {
    await _dbHelper.executeTransaction((txn) async {
      await txn.delete(
        AppConstants.purchaseItemsTable,
        where: 'purchaseId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        AppConstants.purchasesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
