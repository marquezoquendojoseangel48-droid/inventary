import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/inventory_movement.dart';
import '../data/repositories/movement_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final movementRepositoryProvider = Provider<MovementRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MovementRepositorySupabase(supabaseService);
});

final movementsProvider = FutureProvider<List<InventoryMovement>>((ref) async {
  final repository = ref.watch(movementRepositoryProvider);
  return await repository.getAllMovements();
});

final recentMovementsProvider = FutureProvider<List<InventoryMovement>>((ref) async {
  final repository = ref.watch(movementRepositoryProvider);
  return await repository.getRecentMovements(limit: 10);
});

class MovementNotifier extends StateNotifier<AsyncValue<List<InventoryMovement>>> {
  final MovementRepositorySupabase _repository;

  MovementNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMovements();
  }

  Future<void> loadMovements() async {
    state = const AsyncValue.loading();
    try {
      final movements = await _repository.getAllMovements();
      state = AsyncValue.data(movements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMovement(InventoryMovement movement) async {
    try {
      await _repository.createMovement(movement);
      await loadMovements();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> filterByType(MovementType? type) async {
    state = const AsyncValue.loading();
    try {
      if (type == null) {
        final movements = await _repository.getAllMovements();
        state = AsyncValue.data(movements);
      } else {
        final movements = await _repository.getMovementsByType(type);
        state = AsyncValue.data(movements);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final movementListProvider = StateNotifierProvider<MovementNotifier, AsyncValue<List<InventoryMovement>>>((ref) {
  return MovementNotifier(ref.watch(movementRepositoryProvider));
});
