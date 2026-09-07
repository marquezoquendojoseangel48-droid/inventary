import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/inventory_movement.dart';
import '../../core/constants/app_constants.dart';

class MovementRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  MovementRepository(this._dbHelper);

  Future<List<InventoryMovement>> getAllMovements() async {
    final data = await _dbHelper.query(
      AppConstants.movementsTable,
      orderBy: 'date DESC',
    );
    return data.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  Future<List<InventoryMovement>> getMovementsByType(MovementType type) async {
    final data = await _dbHelper.query(
      AppConstants.movementsTable,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'date DESC',
    );
    return data.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  Future<List<InventoryMovement>> getRecentMovements({int limit = 20}) async {
    final data = await _dbHelper.query(
      AppConstants.movementsTable,
      orderBy: 'date DESC',
      limit: limit,
    );
    return data.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  Future<InventoryMovement?> getMovementById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.movementsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return InventoryMovement.fromMap(data.first);
  }

  Future<InventoryMovement> createMovement(InventoryMovement movement) async {
    final newMovement = movement.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    await _dbHelper.insert(AppConstants.movementsTable, newMovement.toMap());
    return newMovement;
  }

  Future<void> deleteMovement(String id) async {
    await _dbHelper.delete(
      AppConstants.movementsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
