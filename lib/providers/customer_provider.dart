import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer.dart';
import '../data/repositories/customer_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final customerRepositoryProvider = Provider<CustomerRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return CustomerRepositorySupabase(supabaseService);
});

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getAllCustomers();
});

final customersWithPendingBalanceProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomersWithPendingBalance();
});

final totalPendingBalanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getTotalPendingBalance();
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepositorySupabase _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _repository.createCustomer(customer);
      await loadCustomers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
      await loadCustomers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchCustomers(String query) async {
    state = const AsyncValue.loading();
    try {
      if (query.isEmpty) {
        final customers = await _repository.getAllCustomers();
        state = AsyncValue.data(customers);
      } else {
        final customers = await _repository.searchCustomers(query);
        state = AsyncValue.data(customers);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePendingBalance(String customerId, double amount) async {
    try {
      await _repository.updatePendingBalance(customerId, amount);
      await loadCustomers();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final customerListProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(ref.watch(customerRepositoryProvider));
});
