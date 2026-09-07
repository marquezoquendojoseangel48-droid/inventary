import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/movement_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../data/models/inventory_movement.dart';
import '../sales/sale_form_screen.dart';
import '../inventory/product_form_screen.dart';
import '../purchases/purchase_form_screen.dart';
import '../payments/payment_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalInventoryValue = ref.watch(totalInventoryValueProvider);
    final totalProductCount = ref.watch(totalProductCountProvider);
    final totalPendingBalance = ref.watch(totalPendingBalanceProvider);
    final recentSales = ref.watch(recentSalesProvider);
    final recentMovements = ref.watch(recentMovementsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalInventoryValueProvider);
            ref.invalidate(totalProductCountProvider);
            ref.invalidate(totalPendingBalanceProvider);
            ref.invalidate(recentSalesProvider);
            ref.invalidate(recentMovementsProvider);
            ref.invalidate(lowStockProductsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // =====================================================
                      // ENCABEZADO
                      // =====================================================
                      _DashboardHeader(
                        onRefresh: () {
                          ref.invalidate(totalInventoryValueProvider);
                          ref.invalidate(totalProductCountProvider);
                          ref.invalidate(totalPendingBalanceProvider);
                          ref.invalidate(recentSalesProvider);
                          ref.invalidate(recentMovementsProvider);
                          ref.invalidate(lowStockProductsProvider);
                        },
                      ),

                      const SizedBox(height: 24),

                      // =====================================================
                      // RESUMEN
                      // =====================================================
                      _SectionHeader(
                        title: 'Resumen',
                        subtitle: 'Estado general del negocio',
                        icon: Icons.dashboard_outlined,
                      ),

                      const SizedBox(height: 12),

                      _StatsGrid(
                        totalInventoryValue: totalInventoryValue,
                        totalProductCount: totalProductCount,
                        totalPendingBalance: totalPendingBalance,
                        recentSales: recentSales,
                      ),

                      const SizedBox(height: 28),

                      // =====================================================
                      // ACCIONES RÁPIDAS
                      // =====================================================
                      _SectionHeader(
                        title: 'Acciones rápidas',
                        subtitle: 'Operaciones frecuentes',
                        icon: Icons.bolt_rounded,
                      ),

                      const SizedBox(height: 12),

                      _QuickActionsGrid(),

                      const SizedBox(height: 28),

                      // =====================================================
                      // ALERTA DE INVENTARIO
                      // =====================================================
                      _SectionHeader(
                        title: 'Inventario',
                        subtitle: 'Productos que requieren atención',
                        icon: Icons.inventory_2_outlined,
                      ),

                      const SizedBox(height: 12),

                      lowStockProducts.when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const _EmptyStateCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Inventario en buen estado',
                              message:
                                  'No hay productos con existencias bajas.',
                            );
                          }

                          return _LowStockCard(
                            products: products,
                          );
                        },
                        loading: () => const _LoadingCard(
                          height: 100,
                        ),
                        error: (error, stack) {
                          return const _ErrorCard(
                            message: 'No se pudo cargar el inventario.',
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // =====================================================
                      // MOVIMIENTOS RECIENTES
                      // =====================================================
                      _SectionHeader(
                        title: 'Actividad reciente',
                        subtitle: 'Últimos movimientos registrados',
                        icon: Icons.history_rounded,
                      ),

                      const SizedBox(height: 12),

                      recentMovements.when(
                        data: (movements) {
                          if (movements.isEmpty) {
                            return const _EmptyStateCard(
                              icon: Icons.history_rounded,
                              title: 'Sin movimientos',
                              message:
                                  'Todavía no hay movimientos registrados.',
                            );
                          }

                          return _RecentMovementsCard(
                            movements: movements,
                          );
                        },
                        loading: () => const _LoadingCard(
                          height: 140,
                        ),
                        error: (error, stack) {
                          return const _ErrorCard(
                            message: 'No se pudieron cargar los movimientos.',
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel principal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Resumen de tu negocio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.refresh_rounded,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STATS
// ============================================================================

class _StatsGrid extends StatelessWidget {
  final AsyncValue<double> totalInventoryValue;
  final AsyncValue<int> totalProductCount;
  final AsyncValue<double> totalPendingBalance;
  final AsyncValue<List<dynamic>> recentSales;

  const _StatsGrid({
    required this.totalInventoryValue,
    required this.totalProductCount,
    required this.totalPendingBalance,
    required this.recentSales,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: width >= 600 ? 1.55 : 1.35,
          children: [
            _StatItem(
              title: 'Valor del inventario',
              value: totalInventoryValue,
              icon: Icons.inventory_2_outlined,
              type: _StatType.currency,
            ),
            _StatItem(
              title: 'Productos',
              value: totalProductCount,
              icon: Icons.category_outlined,
              type: _StatType.integer,
            ),
            _StatItem(
              title: 'Por cobrar',
              value: totalPendingBalance,
              icon: Icons.account_balance_wallet_outlined,
              type: _StatType.currency,
              highlighted: true,
            ),
            _StatItem(
              title: 'Ventas recientes',
              value: recentSales,
              icon: Icons.point_of_sale_outlined,
              type: _StatType.sales,
            ),
          ],
        );
      },
    );
  }
}

enum _StatType {
  currency,
  integer,
  sales,
}

class _StatItem extends StatelessWidget {
  final String title;
  final AsyncValue<dynamic> value;
  final IconData icon;
  final _StatType type;
  final bool highlighted;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.type,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color iconBackground = highlighted
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest;

    final Color iconColor = highlighted
        ? colorScheme.onTertiaryContainer
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: value.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => _StatContent(
          title: title,
          valueText: '—',
          icon: icon,
          iconBackground: iconBackground,
          iconColor: iconColor,
        ),
        data: (data) {
          String valueText;

          switch (type) {
            case _StatType.currency:
              valueText = Formatters.formatCurrency(
                (data as num).toDouble(),
              );
              break;

            case _StatType.integer:
              valueText = data.toString();
              break;

            case _StatType.sales:
              valueText = data.length.toString();
              break;
          }

          return _StatContent(
            title: title,
            valueText: valueText,
            icon: icon,
            iconBackground: iconBackground,
            iconColor: iconColor,
          );
        },
      ),
    );
  }
}

class _StatContent extends StatelessWidget {
  final String title;
  final String valueText;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _StatContent({
    required this.title,
    required this.valueText,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.point_of_sale_rounded,
                title: 'Nueva venta',
                subtitle: 'Registrar venta',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SaleFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_box_outlined,
                title: 'Producto',
                subtitle: 'Agregar producto',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductFormScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.shopping_bag_outlined,
                title: 'Compra',
                subtitle: 'Registrar compra',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.payments_outlined,
                title: 'Pago',
                subtitle: 'Registrar pago',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentFormScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOW STOCK
// ============================================================================

class _LowStockCard extends StatelessWidget {
  final List<dynamic> products;

  const _LowStockCard({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${products.length} producto${products.length == 1 ? '' : 's'} con bajo stock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...products.take(5).map(
                (product) => _LowStockItem(
                  name: product.name,
                  quantity: product.quantity,
                ),
              ),
        ],
      ),
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final String name;
  final dynamic quantity;

  const _LowStockItem({
    required this.name,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$quantity',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT MOVEMENTS
// ============================================================================

class _RecentMovementsCard extends StatelessWidget {
  final List<InventoryMovement> movements;

  const _RecentMovementsCard({
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final visibleMovements = movements.take(7).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          ...List.generate(
            visibleMovements.length,
            (index) {
              final movement = visibleMovements[index];

              return Column(
                children: [
                  _MovementTile(
                    movement: movement,
                  ),
                  if (index != visibleMovements.length - 1)
                    Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 16,
                      color: colorScheme.outlineVariant.withOpacity(0.35),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementTile({
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final movementColor = _getMovementColor(
      context,
      movement.type,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: movementColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _getMovementIcon(movement.type),
              color: movementColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  Formatters.formatDateTime(movement.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (movement.amount != null) ...[
            const SizedBox(width: 10),
            Text(
              Formatters.formatCurrency(
                movement.amount!,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.purchase:
        return Icons.shopping_bag_outlined;

      case MovementType.sale:
        return Icons.point_of_sale_rounded;

      case MovementType.payment:
        return Icons.payments_outlined;

      case MovementType.inventoryAdjustment:
        return Icons.inventory_2_outlined;

      case MovementType.productCreated:
        return Icons.add_circle_outline;
    }
  }

  Color _getMovementColor(
    BuildContext context,
    MovementType type,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case MovementType.purchase:
        return colorScheme.primary;

      case MovementType.sale:
        return colorScheme.tertiary;

      case MovementType.payment:
        return colorScheme.secondary;

      case MovementType.inventoryAdjustment:
        return colorScheme.error;

      case MovementType.productCreated:
        return colorScheme.primary;
    }
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: 23,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: const Center(
        child: LoadingIndicator(),
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}