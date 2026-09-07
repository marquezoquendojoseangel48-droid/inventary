import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_movement.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class MovementRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  MovementRepositorySupabase(this._supabaseService);

  Future<List<InventoryMovement>> getAllMovements() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((map) => InventoryMovement.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryMovement>> getMovementsByType(MovementType type) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .select()
        .eq('type', type.name)
        .order('date', ascending: false);

    return (response as List)
        .map((map) => InventoryMovement.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryMovement>> getRecentMovements({int limit = 20}) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((map) => InventoryMovement.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryMovement?> getMovementById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return InventoryMovement.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<InventoryMovement> createMovement(InventoryMovement movement) async {
    final newMovement = movement.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .insert(newMovement.toSupabaseMap());

    return newMovement;
  }

  Future<void> deleteMovement(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.movementsTable)
        .delete()
        .eq('id', id);
  }
}
