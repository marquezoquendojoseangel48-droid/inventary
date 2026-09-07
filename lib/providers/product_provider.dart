import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository_supabase.dart';
import '../data/supabase/supabase_service.dart';

final productRepositoryProvider = Provider<ProductRepositorySupabase>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ProductRepositorySupabase(supabaseService);
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getAllProducts();
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getLowStockProducts();
});

final totalInventoryValueProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getTotalInventoryValue();
});

final totalProductCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getTotalProductCount();
});

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepositorySupabase _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getAllProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _repository.createProduct(product);
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchProducts(String query) async {
    state = const AsyncValue.loading();
    try {
      if (query.isEmpty) {
        final products = await _repository.getAllProducts();
        state = AsyncValue.data(products);
      } else {
        final products = await _repository.searchProducts(query);
        state = AsyncValue.data(products);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final productListProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier(ref.watch(productRepositoryProvider));
});
