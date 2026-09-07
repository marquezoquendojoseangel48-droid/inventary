import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/supplier.dart';
import '../data/repositories/supplier_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final supplierRepositoryProvider = Provider<SupplierRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SupplierRepositorySupabase(supabaseService);
});

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final repository = ref.watch(supplierRepositoryProvider);
  return await repository.getAllSuppliers();
});

class SupplierNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  final SupplierRepositorySupabase _repository;

  SupplierNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    state = const AsyncValue.loading();
    try {
      final suppliers = await _repository.getAllSuppliers();
      state = AsyncValue.data(suppliers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _repository.createSupplier(supplier);
      await loadSuppliers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _repository.updateSupplier(supplier);
      await loadSuppliers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      await loadSuppliers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchSuppliers(String query) async {
    state = const AsyncValue.loading();
    try {
      if (query.isEmpty) {
        final suppliers = await _repository.getAllSuppliers();
        state = AsyncValue.data(suppliers);
      } else {
        final suppliers = await _repository.searchSuppliers(query);
        state = AsyncValue.data(suppliers);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final supplierListProvider = StateNotifierProvider<SupplierNotifier, AsyncValue<List<Supplier>>>((ref) {
  return SupplierNotifier(ref.watch(supplierRepositoryProvider));
});
