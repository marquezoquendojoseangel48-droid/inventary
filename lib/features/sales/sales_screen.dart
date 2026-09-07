import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/sale.dart';
import 'sale_form_screen.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
      ),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart,
              title: 'No hay ventas',
              subtitle: 'Toca el botón + para registrar la primera venta',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(saleListProvider.notifier).loadSales();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return _SaleCard(
                  sale: sale,
                  onTap: () {
                    // TODO: Show sale details
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
                  ref.read(saleListProvider.notifier).loadSales();
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
              builder: (context) => const SaleFormScreen(),
            ),
          );
          if (result == true) {
            ref.read(saleListProvider.notifier).loadSales();
          }
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva Venta'),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const _SaleCard({
    required this.sale,
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
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${sale.id.substring(0, 8)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDateTime(sale.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(sale.total),
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
              if (sale.customerId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Cliente: ${sale.customerId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calculate,
                    label: 'Subtotal: ${Formatters.formatCurrency(sale.subtotal)}',
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
