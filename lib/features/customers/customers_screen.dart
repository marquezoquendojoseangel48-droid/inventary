import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customer_provider.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clientes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar cliente',
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch<String>(
                context: context,
                delegate: CustomerSearchDelegate(),
              );
            },
          ),
        ],
      ),

      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const EmptyState(
              icon: Icons.people,
              title: 'No hay clientes',
              subtitle: 'Toca el botón + para agregar el primero',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(customerListProvider.notifier)
                  .loadCustomers();
            },

            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];

                return _CustomerCard(
                  customer: customer,

                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerFormScreen(customer: customer),
                      ),
                    );

                    if (result == true && mounted) {
                      ref
                          .read(customerListProvider.notifier)
                          .loadCustomers();
                    }
                  },

                  onDelete: () async {
                    final confirmed =
                        await _showDeleteConfirmation(
                      context,
                      customer.name,
                    );

                    if (confirmed && mounted) {
                      await ref
                          .read(customerListProvider.notifier)
                          .deleteCustomer(customer.id);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cliente eliminado'),
                          ),
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

        error: (error, stack) {
          return _ErrorView(
            error: error,
            onRetry: () {
              ref
                  .read(customerListProvider.notifier)
                  .loadCustomers();
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerFormScreen(),
            ),
          );

          if (result == true && mounted) {
            ref
                .read(customerListProvider.notifier)
                .loadCustomers();
          }
        },

        icon: const Icon(Icons.add),

        label: const Text(
          'Agregar Cliente',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String customerName,
  ) async {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              title: const Text(
                'Eliminar Cliente',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth > 500
                      ? 450
                      : screenWidth - 48,
                ),

                child: SingleChildScrollView(
                  child: Text(
                    '¿Estás seguro de eliminar "$customerName"?',
                    softWrap: true,
                  ),
                ),
              ),

              actionsOverflowDirection:
                  VerticalDirection.down,

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancelar'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasPendingBalance =
        customer.pendingBalance > 0;

    final customerName =
        customer.name.trim().isEmpty
            ? 'Cliente sin nombre'
            : customer.name.trim();

    final phone = customer.phone?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxWidth < 360;

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        _CustomerIdentity(
                          customerName: customerName,
                          phone: phone,
                          theme: theme,
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            if (hasPendingBalance)
                              _PendingBadge(),

                            const Spacer(),

                            _CustomerMenu(
                              onEdit: onTap,
                              onDelete: onDelete,
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: _CustomerIdentity(
                          customerName: customerName,
                          phone: phone,
                          theme: theme,
                        ),
                      ),

                      const SizedBox(width: 8),

                      if (hasPendingBalance)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 2,
                          ),
                          child: _PendingBadge(),
                        ),

                      _CustomerMenu(
                        onEdit: onTap,
                        onDelete: onDelete,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              /*
               * IMPORTANTE:
               *
               * Antes había un Row con dos InfoChip.
               *
               * Si el saldo era largo, por ejemplo:
               *
               * $ 12.500.000.000
               *
               * el contenido podía salirse horizontalmente.
               *
               * Wrap permite que los elementos bajen
               * automáticamente a la siguiente línea.
               */
              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: [
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label:
                        'Registrado: ${Formatters.formatDate(customer.createdAt)}',
                    color: Colors.grey,
                  ),

                  _InfoChip(
                    icon:
                        Icons.account_balance_wallet,
                    label:
                        'Saldo: ${Formatters.formatCurrency(customer.pendingBalance)}',
                    color: hasPendingBalance
                        ? Colors.orange
                        : Colors.green,
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

class _CustomerIdentity extends StatelessWidget {
  final String customerName;
  final String? phone;
  final ThemeData theme;

  const _CustomerIdentity({
    required this.customerName,
    required this.phone,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      mainAxisSize: MainAxisSize.min,

      children: [
        Text(
          customerName,

          maxLines: 2,

          overflow:
              TextOverflow.ellipsis,

          softWrap: true,

          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        if (phone != null &&
            phone!.isNotEmpty) ...[
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.phone,
                size: 14,
                color: Colors.grey,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  phone!,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: theme.textTheme.bodySmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 100,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.orange
            .withOpacity(0.1),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: const Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 15,
            color: Colors.orange,
          ),

          SizedBox(width: 4),

          Flexible(
            child: Text(
              'Debe',

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Opciones',

      icon: const Icon(
        Icons.more_vert,
      ),

      onPressed: () {
        showModalBottomSheet(
          context: context,

          isScrollControlled: true,

          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context)
                        .height *
                    0.8,
          ),

          builder: (bottomContext) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.edit),

                      title: const Text(
                        'Editar',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                      onTap: () {
                        Navigator.pop(
                          bottomContext,
                        );

                        onEdit();
                      },
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),

                      title: const Text(
                        'Eliminar',

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),

                      onTap: () {
                        Navigator.pop(
                          bottomContext,
                        );

                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    /*
     * El chip no puede ocupar más
     * que el ancho disponible.
     */
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            MediaQuery.sizeOf(context).width -
                64;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),

          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.1),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),

                const SizedBox(width: 6),

                Flexible(
                  child: Text(
                    label,

                    maxLines: 2,

                    softWrap: true,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 500,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),

                const SizedBox(height: 16),

                Text(
                  'Ocurrió un error',

                  textAlign:
                      TextAlign.center,

                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  error.toString(),

                  maxLines: 5,

                  overflow:
                      TextOverflow.ellipsis,

                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: onRetry,

                  child:
                      const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerSearchDelegate
    extends SearchDelegate<String> {
  CustomerSearchDelegate();

  @override
  String get searchFieldLabel =>
      'Buscar cliente';

  @override
  List<Widget>? buildActions(
    BuildContext context,
  ) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Limpiar',

          icon:
              const Icon(Icons.clear),

          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(
    BuildContext context,
  ) {
    return IconButton(
      tooltip: 'Volver',

      icon:
          const Icon(Icons.arrow_back),

      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(
    BuildContext context,
  ) {
    return _SearchCustomersView(
      query: query,
    );
  }

  @override
  Widget buildSuggestions(
    BuildContext context,
  ) {
    return _SearchCustomersView(
      query: query,
    );
  }
}

class _SearchCustomersView
    extends ConsumerWidget {
  final String query;

  const _SearchCustomersView({
    required this.query,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final customersAsync =
        ref.watch(customerListProvider);

    return customersAsync.when(
      data: (customers) {
        final normalizedQuery =
            query.trim().toLowerCase();

        final filtered = normalizedQuery
                .isEmpty
            ? customers
            : customers.where((customer) {
                final name =
                    customer.name.toLowerCase();

                final phone =
                    customer.phone
                        ?.toLowerCase() ??
                        '';

                return name.contains(
                      normalizedQuery,
                    ) ||
                    phone.contains(
                      normalizedQuery,
                    );
              }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title:
                'No se encontraron clientes',
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ),

          itemCount:
              filtered.length,

          itemBuilder:
              (context, index) {
            final customer =
                filtered[index];

            return _CustomerCard(
              customer: customer,

              onTap: () async {
                final result =
                    await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerFormScreen(
                      customer: customer,
                    ),
                  ),
                );

                if (result == true &&
                    context.mounted) {
                  ref
                      .read(
                        customerListProvider
                            .notifier,
                      )
                      .loadCustomers();
                }
              },

              onDelete: () async {
                final confirmed =
                    await _showDeleteConfirmation(
                  context,
                  customer.name,
                );

                if (confirmed &&
                    context.mounted) {
                  await ref
                      .read(
                        customerListProvider
                            .notifier,
                      )
                      .deleteCustomer(
                        customer.id,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cliente eliminado',
                        ),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },

      loading: () =>
          const LoadingIndicator(),

      error: (error, stack) {
        return _ErrorView(
          error: error,
          onRetry: () {
            ref
                .read(
                  customerListProvider
                      .notifier,
                )
                .loadCustomers();
          },
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String customerName,
  ) async {
    return await showDialog<bool>(
          context: context,

          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Eliminar Cliente',
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
              ),

              content:
                  SingleChildScrollView(
                child: Text(
                  '¿Estás seguro de eliminar "$customerName"?',
                  softWrap: true,
                ),
              ),

              actionsOverflowDirection:
                  VerticalDirection.down,

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },

                  child:
                      const Text('Cancelar'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },

                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        Colors.red,
                  ),

                  child:
                      const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}