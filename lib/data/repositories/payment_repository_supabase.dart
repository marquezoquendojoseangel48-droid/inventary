import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';
import '../supabase/supabase_service.dart';
import '../../core/config/supabase_config.dart';

class PaymentRepositorySupabase {
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  PaymentRepositorySupabase(this._supabaseService);

  Future<List<Payment>> getAllPayments() async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.paymentsTable)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((map) => Payment.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> getPaymentsByCustomer(String customerId) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.paymentsTable)
        .select()
        .eq('customerId', customerId)
        .order('date', ascending: false);

    return (response as List)
        .map((map) => Payment.fromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Payment?> getPaymentById(String id) async {
    final response = await _supabaseService.client
        .from(SupabaseConfig.paymentsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Payment.fromSupabaseMap(response as Map<String, dynamic>);
  }

  Future<Payment> createPayment(Payment payment) async {
    final newPayment = payment.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );

    await _supabaseService.client
        .from(SupabaseConfig.paymentsTable)
        .insert(newPayment.toSupabaseMap());

    return newPayment;
  }

  Future<void> deletePayment(String id) async {
    await _supabaseService.client
        .from(SupabaseConfig.paymentsTable)
        .delete()
        .eq('id', id);
  }
}
