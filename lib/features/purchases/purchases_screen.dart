import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/purchase_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/purchase.dart';
import 'purchase_form_screen.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchaseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras a Proveedores'),
      ),
      body: purchasesAsync.when(
        data: (purchases) {
          if (purchases.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag,
              title: 'No hay compras',
              subtitle: 'Toca el botón + para registrar la primera compra',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(purchaseListProvider.notifier).loadPurchases();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return _PurchaseCard(
                  purchase: purchase,
                  onTap: () {
                    // TODO: Show purchase details
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
                  ref.read(purchaseListProvider.notifier).loadPurchases();
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
              builder: (context) => const PurchaseFormScreen(),
            ),
          );
          if (result == true) {
            ref.read(purchaseListProvider.notifier).loadPurchases();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Compra'),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback onTap;

  const _PurchaseCard({
    required this.purchase,
    required this.onTap,
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
                      Icons.shopping_bag,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compra #${purchase.id.substring(0, 8)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDateTime(purchase.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(purchase.total),
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.business,
                    label: 'Proveedor: ${purchase.supplierId.substring(0, 8)}',
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
