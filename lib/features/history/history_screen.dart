import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/movement_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/inventory_movement.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  MovementType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(movementListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Movimientos'),
        actions: [
          PopupMenuButton<MovementType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
              ref.read(movementListProvider.notifier).filterByType(filter);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: MovementType.purchase,
                child: Text('Compras'),
              ),
              const PopupMenuItem(
                value: MovementType.sale,
                child: Text('Ventas'),
              ),
              const PopupMenuItem(
                value: MovementType.payment,
                child: Text('Pagos'),
              ),
              const PopupMenuItem(
                value: MovementType.inventoryAdjustment,
                child: Text('Ajustes de Inventario'),
              ),
              const PopupMenuItem(
                value: MovementType.productCreated,
                child: Text('Productos Creados'),
              ),
            ],
          ),
        ],
      ),
      body: movementsAsync.when(
        data: (movements) {
          if (movements.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'No hay movimientos',
              subtitle: 'Los movimientos se registrarán automáticamente',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(movementListProvider.notifier).loadMovements();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                return _MovementTile(movement: movement);
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
                  ref.read(movementListProvider.notifier).loadMovements();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMovementColor(movement.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMovementIcon(movement.type),
                color: _getMovementColor(movement.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDateTime(movement.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (movement.amount != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(movement.amount!),
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getMovementColor(movement.type),
                        ),
                  ),
                  Text(
                    movement.typeDisplayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              )
            else
              Text(
                movement.typeDisplayName,
                style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.purchase:
        return Icons.shopping_bag;
      case MovementType.sale:
        return Icons.point_of_sale;
      case MovementType.payment:
        return Icons.payment;
      case MovementType.inventoryAdjustment:
        return Icons.inventory;
      case MovementType.productCreated:
        return Icons.add_circle;
    }
  }

  Color _getMovementColor(MovementType type) {
    switch (type) {
      case MovementType.purchase:
        return Colors.orange;
      case MovementType.sale:
        return Colors.green;
      case MovementType.payment:
        return Colors.purple;
      case MovementType.inventoryAdjustment:
        return Colors.blue;
      case MovementType.productCreated:
        return Colors.teal;
    }
  }
}
