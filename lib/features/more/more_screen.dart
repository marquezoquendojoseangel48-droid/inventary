import 'package:flutter/material.dart';
import '../purchases/purchases_screen.dart';
import '../payments/payments_screen.dart';
import '../history/history_screen.dart';
import '../suppliers/suppliers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuSection(
            title: 'Operaciones',
            items: [
              _MenuItem(
                icon: Icons.business,
                title: 'Proveedores',
                subtitle: 'Gestionar proveedores',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SuppliersScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.shopping_bag,
                title: 'Compras a Proveedores',
                subtitle: 'Registrar compras de mercancía',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PurchasesScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.payment,
                title: 'Pagos y Abonos',
                subtitle: 'Registrar pagos de clientes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MenuSection(
            title: 'Información',
            items: [
              _MenuItem(
                icon: Icons.history,
                title: 'Historial de Movimientos',
                subtitle: 'Ver todos los movimientos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
