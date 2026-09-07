import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class PurchaseRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  PurchaseRepositorySupabase(this._supabaseService);

  Future<List<Purchase>> getAllPurchases() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.purchasesTable)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((map) => Purchase.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase?> getPurchaseById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.purchasesTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Purchase.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.purchaseItemsTable)
        .select()
        .eq('purchaseId', purchaseId);

    return (response as List)
        .map((map) => PurchaseItem.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> createPurchaseWithItems(
    Purchase purchase,
    List<PurchaseItem> items,
  ) async {
    final newPurchase = purchase.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.purchasesTable)
        .insert(newPurchase.toSupabaseMap());

    for (var item in items) {
      final newItem = item.copyWith(
        id: _uuid.v4(),
        purchaseId: newPurchase.id,
      );
      await _supabaseService.client
          .from(SupabaseConfig.purchaseItemsTable)
          .insert(newItem.toSupabaseMap());
    }

    return newPurchase;
  }

  Future<void> deletePurchase(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.purchaseItemsTable)
        .delete()
        .eq('purchaseId', id);

    await _supabaseService.client
        .from(SupabaseConfig.purchasesTable)
        .delete()
        .eq('id', id);
  }
}
