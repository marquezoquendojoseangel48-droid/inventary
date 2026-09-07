import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import 'product_form_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(ref),
              );
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final filteredProducts = _searchQuery.isEmpty
              ? products
              : products
                  .where((p) =>
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                  .toList();

          if (filteredProducts.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2,
              title: 'No hay productos',
              subtitle: 'Toca el botón + para agregar el primero',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(productListProvider.notifier).loadProducts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _ProductCard(
                  product: product,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(product: product),
                      ),
                    );
                    if (result == true) {
                      ref.read(productListProvider.notifier).loadProducts();
                    }
                  },
                  onDelete: () async {
                    final confirmed = await _showDeleteConfirmation(context, product.name);
                    if (confirmed && mounted) {
                      await ref.read(productListProvider.notifier).deleteProduct(product.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto eliminado')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(productListProvider.notifier).loadProducts();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
          if (result == true && mounted) {
            ref.read(productListProvider.notifier).loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String productName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text('¿Estás seguro de eliminar "$productName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (product.description != null && product.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Bajo Stock',
                            style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Editar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  onTap();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.inventory_2,
                    label: 'Cantidad: ${product.quantity}',
                    color: product.quantity > product.minStock ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.sell,
                    label: Formatters.formatCurrency(product.salePrice),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.shopping_cart,
                    label: 'Compra: ${Formatters.formatCurrency(product.purchasePrice)}',
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.minimize,
                    label: 'Mín: ${product.minStock}',
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  ProductSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, child) {
        final productsAsync = ref.watch(productListProvider);

        return productsAsync.when(
          data: (products) {
            final filtered = products
                .where((p) =>
                    p.name.toLowerCase().contains(query.toLowerCase()) ||
                    (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
                .toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                icon: Icons.search_off,
                title: 'No se encontraron productos',
              );
            }

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ProductCard(
                  product: product,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(product: product),
                      ),
                    );
                    if (result == true) {
                      ref.read(productListProvider.notifier).loadProducts();
                    }
                  },
                  onDelete: () async {
                    final confirmed = await _showDeleteConfirmation(context, product.name);
                    if (confirmed && context.mounted) {
                      await ref.read(productListProvider.notifier).deleteProduct(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto eliminado')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String productName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text('¿Estás seguro de eliminar "$productName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
