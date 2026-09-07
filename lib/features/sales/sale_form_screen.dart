import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/movement_provider.dart';
import '../../data/models/sale.dart';
import '../../data/models/product.dart';
import '../../data/models/customer.dart';
import '../../data/models/inventory_movement.dart';
import '../../core/utils/formatters.dart';

class SaleFormScreen extends ConsumerStatefulWidget {
  const SaleFormScreen({super.key});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final List<_SaleItem> _items = [];
  Customer? _selectedCustomer;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal;

  Future<void> _addItem() async {
    final productsAsync = ref.read(productListProvider);
    final products = productsAsync.value ?? [];
    if (!mounted) return;

    final selectedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => _ProductSelectorDialog(products: products),
    );

    if (selectedProduct != null && mounted) {
      final quantity = await showDialog<int>(
        context: context,
        builder: (context) => _QuantityDialog(
          product: selectedProduct,
          maxQuantity: selectedProduct.quantity,
        ),
      );

      if (quantity != null && quantity > 0 && mounted) {
        setState(() {
          final existingIndex = _items.indexWhere((item) => item.product.id == selectedProduct.id);
          if (existingIndex >= 0) {
            _items[existingIndex] = _SaleItem(
              product: selectedProduct,
              quantity: _items[existingIndex].quantity + quantity,
              unitPrice: selectedProduct.salePrice,
            );
          } else {
            _items.add(_SaleItem(
              product: selectedProduct,
              quantity: quantity,
              unitPrice: selectedProduct.salePrice,
            ));
          }
        });
      }
    }
  }

  Future<void> _selectCustomer() async {
    final customersAsync = ref.read(customerListProvider);
    final customers = customersAsync.value ?? [];
    if (!mounted) return;

    final selected = await showDialog<Customer>(
      context: context,
      builder: (context) => _CustomerSelectorDialog(customers: customers),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCustomer = selected;
      });
    }
  }

  Future<void> _completeSale() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sale = Sale(
        id: '',
        customerId: _selectedCustomer?.id,
        date: DateTime.now(),
        subtotal: _subtotal,
        total: _total,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final saleItems = _items.map((item) {
        return SaleItem(
          id: '',
          saleId: '',
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
        );
      }).toList();

      // Create sale
      await ref.read(saleListProvider.notifier).createSaleWithItems(sale, saleItems);

      // Update inventory
      for (var item in _items) {
        await ref.read(productRepositoryProvider).updateProductQuantity(
              item.product.id,
              -item.quantity,
            );
      }

      // Update customer balance if credit sale
      if (_selectedCustomer != null) {
        await ref.read(customerListProvider.notifier).updatePendingBalance(
              _selectedCustomer!.id,
              _total,
            );
      }

      // Register movement
      final movement = InventoryMovement(
        id: '',
        type: MovementType.sale,
        description: 'Venta de ${_items.length} productos',
        date: DateTime.now(),
        amount: _total,
        relatedId: sale.id,
        createdAt: DateTime.now(),
      );
      await ref.read(movementListProvider.notifier).addMovement(movement);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      _selectedCustomer?.name ?? 'Seleccionar Cliente (opcional)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectCustomer,
                  ),
                ),
                const SizedBox(height: 16),

                // Items List
                Text(
                  'Productos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No hay productos',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                          '${item.quantity} x ${Formatters.formatCurrency(item.unitPrice)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.formatCurrency(item.total),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Agrega notas sobre esta venta',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),

          // Bottom Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        Formatters.formatCurrency(_subtotal),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        Formatters.formatCurrency(_total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Producto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _items.isEmpty ? null : _completeSale,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isLoading ? 'Procesando...' : 'Completar Venta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleItem {
  final Product product;
  final int quantity;
  final double unitPrice;

  _SaleItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class _ProductSelectorDialog extends StatefulWidget {
  final List<Product> products;

  const _ProductSelectorDialog({required this.products});

  @override
  State<_ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<_ProductSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    return widget.products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Producto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o descripción...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(child: Text('No se encontraron productos'))
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            'Disponible: ${product.quantity} - ${Formatters.formatCurrency(product.salePrice)}',
                          ),
                          enabled: product.quantity > 0,
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  final Product product;
  final int maxQuantity;

  const _QuantityDialog({
    required this.product,
    required this.maxQuantity,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Disponible: ${widget.maxQuantity}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              hintText: '1',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final quantity = int.tryParse(_controller.text);
            if (quantity != null && quantity > 0 && quantity <= widget.maxQuantity) {
              Navigator.pop(context, quantity);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cantidad inválida')),
              );
            }
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _CustomerSelectorDialog extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectorDialog({required this.customers});

  @override
  State<_CustomerSelectorDialog> createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends State<_CustomerSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return widget.customers;
    return widget.customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? const Center(child: Text('No se encontraron clientes'))
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: customer.phone != null ? Text(customer.phone!) : null,
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Sin Cliente'),
        ),
      ],
    );
  }
}
