import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/purchase.dart';
import '../data/repositories/purchase_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PurchaseRepositorySupabase(supabaseService);
});

final purchasesProvider = FutureProvider<List<Purchase>>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return await repository.getAllPurchases();
});

class PurchaseNotifier extends StateNotifier<AsyncValue<List<Purchase>>> {
  final PurchaseRepositorySupabase _repository;

  PurchaseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    state = const AsyncValue.loading();
    try {
      final purchases = await _repository.getAllPurchases();
      state = AsyncValue.data(purchases);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createPurchaseWithItems(Purchase purchase, List<PurchaseItem> items) async {
    try {
      await _repository.createPurchaseWithItems(purchase, items);
      await loadPurchases();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePurchase(String id) async {
    try {
      await _repository.deletePurchase(id);
      await loadPurchases();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final purchaseListProvider = StateNotifierProvider<PurchaseNotifier, AsyncValue<List<Purchase>>>((ref) {
  return PurchaseNotifier(ref.watch(purchaseRepositoryProvider));
});
