import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment.dart';
import 'payment_form_screen.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos y Abonos'),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return EmptyState(
              icon: Icons.payment,
              title: 'No hay pagos registrados',
              subtitle: 'Toca el botón + para registrar un pago',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(paymentListProvider.notifier).loadPayments();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _PaymentCard(
                  payment: payment,
                  onTap: () {
                    // TODO: Show payment details
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
                  ref.read(paymentListProvider.notifier).loadPayments();
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
              builder: (context) => const PaymentFormScreen(),
            ),
          );
          if (result == true) {
            ref.read(paymentListProvider.notifier).loadPayments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar Pago'),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.payment,
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
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago #${payment.id.substring(0, 8)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDateTime(payment.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(payment.amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.person,
                    label: 'Cliente: ${payment.customerId.substring(0, 8)}',
                    color: Colors.grey,
                  ),
                ],
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  payment.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
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
