import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../data/models/supplier.dart';
import 'supplier_form_screen.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SupplierSearchDelegate(ref),
              );
            },
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          final filteredSuppliers = _searchQuery.isEmpty
              ? suppliers
              : suppliers
                  .where((s) =>
                      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (s.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                  .toList();

          if (filteredSuppliers.isEmpty) {
            return EmptyState(
              icon: Icons.business,
              title: 'No hay proveedores',
              subtitle: 'Toca el botón + para agregar el primero',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(supplierListProvider.notifier).loadSuppliers();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = filteredSuppliers[index];
                return _SupplierCard(
                  supplier: supplier,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupplierFormScreen(supplier: supplier),
                      ),
                    );
                    if (result == true) {
                      ref.read(supplierListProvider.notifier).loadSuppliers();
                    }
                  },
                  onDelete: () async {
                    final confirmed = await _showDeleteConfirmation(context, supplier.name);
                    if (confirmed && mounted) {
                      await ref.read(supplierListProvider.notifier).deleteSupplier(supplier.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proveedor eliminado')),
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
                  ref.read(supplierListProvider.notifier).loadSuppliers();
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
              builder: (context) => const SupplierFormScreen(),
            ),
          );
          if (result == true && mounted) {
            ref.read(supplierListProvider.notifier).loadSuppliers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Proveedor'),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String supplierName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Proveedor'),
            content: Text('¿Estás seguro de eliminar "$supplierName"?'),
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

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                supplier.phone!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
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
              if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        supplier.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SupplierSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  SupplierSearchDelegate(this.ref);

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
        final suppliersAsync = ref.watch(supplierListProvider);

        return suppliersAsync.when(
          data: (suppliers) {
            final filtered = suppliers
                .where((s) =>
                    s.name.toLowerCase().contains(query.toLowerCase()) ||
                    (s.phone?.toLowerCase().contains(query.toLowerCase()) ?? false))
                .toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                icon: Icons.search_off,
                title: 'No se encontraron proveedores',
              );
            }

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final supplier = filtered[index];
                return _SupplierCard(
                  supplier: supplier,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupplierFormScreen(supplier: supplier),
                      ),
                    );
                    if (result == true) {
                      ref.read(supplierListProvider.notifier).loadSuppliers();
                    }
                  },
                  onDelete: () async {
                    final confirmed = await _showDeleteConfirmation(context, supplier.name);
                    if (confirmed && context.mounted) {
                      await ref.read(supplierListProvider.notifier).deleteSupplier(supplier.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proveedor eliminado')),
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

  Future<bool> _showDeleteConfirmation(BuildContext context, String supplierName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Proveedor'),
            content: Text('¿Estás seguro de eliminar "$supplierName"?'),
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
