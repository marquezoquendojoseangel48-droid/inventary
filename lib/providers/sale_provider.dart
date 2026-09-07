import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sale.dart';
import '../data/repositories/sale_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final saleRepositoryProvider = Provider<SaleRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SaleRepositorySupabase(supabaseService);
});

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final repository = ref.watch(saleRepositoryProvider);
  return await repository.getAllSales();
});

final recentSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final repository = ref.watch(saleRepositoryProvider);
  return await repository.getRecentSales(limit: 5);
});

class SaleNotifier extends StateNotifier<AsyncValue<List<Sale>>> {
  final SaleRepositorySupabase _repository;

  SaleNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSales();
  }

  Future<void> loadSales() async {
    state = const AsyncValue.loading();
    try {
      final sales = await _repository.getAllSales();
      state = AsyncValue.data(sales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createSaleWithItems(Sale sale, List<SaleItem> items) async {
    try {
      await _repository.createSaleWithItems(sale, items);
      await loadSales();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _repository.deleteSale(id);
      await loadSales();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final saleListProvider = StateNotifierProvider<SaleNotifier, AsyncValue<List<Sale>>>((ref) {
  return SaleNotifier(ref.watch(saleRepositoryProvider));
});
