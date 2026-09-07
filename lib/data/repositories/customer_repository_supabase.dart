import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class CustomerRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  CustomerRepositorySupabase(this._supabaseService);

  Future<List<Customer>> getAllCustomers() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Customer.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Customer.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .select()
        .or('name.ilike.%$query%,phone.ilike.%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Customer.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Customer>> getCustomersWithPendingBalance() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .select()
        .gt('pendingBalance', 0)
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Customer.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final newCustomer = customer.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingBalance: customer.pendingBalance,
    );

    await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .insert(newCustomer.toSupabaseMap());

    return newCustomer;
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final updatedCustomer = customer.copyWith(
      updatedAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .update(updatedCustomer.toSupabaseMap())
        .eq('id', customer.id);

    return updatedCustomer;
  }

  Future<void> deleteCustomer(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.customersTable)
        .delete()
        .eq('id', id);
  }

  Future<void> updatePendingBalance(String customerId, double amount) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      throw Exception('Cliente no encontrado');
    }

    final newBalance = customer.pendingBalance + amount;
    if (newBalance < 0) {
      throw Exception('El pago no puede superar el saldo pendiente');
    }

    await updateCustomer(customer.copyWith(pendingBalance: newBalance));
  }

  Future<double> getTotalPendingBalance() async {
    final customers = await getAllCustomers();
    return customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.pendingBalance,
    );
  }
}
