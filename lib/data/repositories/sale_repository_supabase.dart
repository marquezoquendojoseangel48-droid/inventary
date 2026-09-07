import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class SaleRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  SaleRepositorySupabase(this._supabaseService);

  Future<List<Sale>> getAllSales() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.salesTable)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((map) => Sale.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Sale>> getRecentSales({int limit = 10}) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.salesTable)
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((map) => Sale.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Sale?> getSaleById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.salesTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Sale.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.saleItemsTable)
        .select()
        .eq('saleId', saleId);

    return (response as List)
        .map((map) => SaleItem.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Sale> createSaleWithItems(
    Sale sale,
    List<SaleItem> items,
  ) async {
    final newSale = sale.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.salesTable)
        .insert(newSale.toSupabaseMap());

    for (var item in items) {
      final newItem = item.copyWith(
        id: _uuid.v4(),
        saleId: newSale.id,
      );
      await _supabaseService.client
          .from(SupabaseConfig.saleItemsTable)
          .insert(newItem.toSupabaseMap());
    }

    return newSale;
  }

  Future<void> deleteSale(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.saleItemsTable)
        .delete()
        .eq('saleId', id);

    await _supabaseService.client
        .from(SupabaseConfig.salesTable)
        .delete()
        .eq('id', id);
  }
}
