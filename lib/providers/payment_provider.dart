import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/payment.dart';
import '../data/repositories/payment_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final paymentRepositoryProvider = Provider<PaymentRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PaymentRepositorySupabase(supabaseService);
});

final paymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getAllPayments();
});

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final PaymentRepositorySupabase _repository;

  PaymentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final payments = await _repository.getAllPayments();
      state = AsyncValue.data(payments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPayment(Payment payment) async {
    try {
      await _repository.createPayment(payment);
      await loadPayments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _repository.deletePayment(id);
      await loadPayments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final paymentListProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>((ref) {
  return PaymentNotifier(ref.watch(paymentRepositoryProvider));
});
