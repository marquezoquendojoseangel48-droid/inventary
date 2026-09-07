import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class SupplierRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  SupplierRepositorySupabase(this._supabaseService);

  Future<List<Supplier>> getAllSuppliers() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Supplier.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Supplier.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .select()
        .ilike('name', '%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Supplier.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final newSupplier = supplier.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .insert(newSupplier.toSupabaseMap());

    return newSupplier;
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    final updatedSupplier = supplier.copyWith(
      updatedAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .update(updatedSupplier.toSupabaseMap())
        .eq('id', supplier.id);

    return updatedSupplier;
  }

  Future<void> deleteSupplier(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.suppliersTable)
        .delete()
        .eq('id', id);
  }
}
