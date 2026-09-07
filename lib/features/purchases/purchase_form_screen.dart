import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/movement_provider.dart';
import '../../data/models/purchase.dart';
import '../../data/models/product.dart';
import '../../data/models/supplier.dart';
import '../../data/models/inventory_movement.dart';
import '../../core/utils/formatters.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final List<_PurchaseItem> _items = [];
  Supplier? _selectedSupplier;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (sum, item) => sum + item.total);

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
        builder: (context) => _PurchaseQuantityDialog(
          product: selectedProduct,
        ),
      );

      if (quantity != null && quantity > 0 && mounted) {
        final unitPrice = await showDialog<double>(
          context: context,
          builder: (context) => _PriceDialog(
            product: selectedProduct,
            defaultPrice: selectedProduct.purchasePrice,
          ),
        );

        if (unitPrice != null && unitPrice >= 0 && mounted) {
          setState(() {
            final existingIndex = _items.indexWhere((item) => item.product.id == selectedProduct.id);
            if (existingIndex >= 0) {
              _items[existingIndex] = _PurchaseItem(
                product: selectedProduct,
                quantity: _items[existingIndex].quantity + quantity,
                unitPrice: unitPrice,
              );
            } else {
              _items.add(_PurchaseItem(
                product: selectedProduct,
                quantity: quantity,
                unitPrice: unitPrice,
              ));
            }
          });
        }
      }
    }
  }

  Future<void> _selectSupplier() async {
    final suppliersAsync = ref.read(supplierListProvider);
    final suppliers = suppliersAsync.value ?? [];
    if (!mounted) return;

    final selected = await showDialog<Supplier>(
      context: context,
      builder: (context) => _SupplierSelectorDialog(suppliers: suppliers),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedSupplier = selected;
      });
    }
  }

  Future<void> _completePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor')),
      );
      return;
    }

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
      final purchase = Purchase(
        id: '',
        supplierId: _selectedSupplier!.id,
        date: DateTime.now(),
        total: _total,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final purchaseItems = _items.map((item) {
        return PurchaseItem(
          id: '',
          purchaseId: '',
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
        );
      }).toList();

      // Create purchase
      await ref.read(purchaseListProvider.notifier).createPurchaseWithItems(purchase, purchaseItems);

      // Update inventory
      for (var item in _items) {
        await ref.read(productRepositoryProvider).updateProductQuantity(
              item.product.id,
              item.quantity,
            );
      }

      // Register movement
      final movement = InventoryMovement(
        id: '',
        type: MovementType.purchase,
        description: 'Compra a ${_selectedSupplier!.name}',
        date: DateTime.now(),
        amount: _total,
        relatedId: purchase.id,
        createdAt: DateTime.now(),
      );
      await ref.read(movementListProvider.notifier).addMovement(movement);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada exitosamente')),
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
        title: const Text('Nueva Compra'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Supplier Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(
                      _selectedSupplier?.name ?? 'Seleccionar Proveedor',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectSupplier,
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
                              Icons.inventory_2_outlined,
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
                    hintText: 'Agrega notas sobre esta compra',
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
                        'Total:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        Formatters.formatCurrency(_total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
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
                          onPressed: _isLoading || _items.isEmpty ? null : _completePurchase,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isLoading ? 'Procesando...' : 'Completar Compra'),
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

class _PurchaseItem {
  final Product product;
  final int quantity;
  final double unitPrice;

  _PurchaseItem({
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
                            'Compra: ${Formatters.formatCurrency(product.purchasePrice)}',
                          ),
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

class _PurchaseQuantityDialog extends StatefulWidget {
  final Product product;

  const _PurchaseQuantityDialog({required this.product});

  @override
  State<_PurchaseQuantityDialog> createState() => _PurchaseQuantityDialogState();
}

class _PurchaseQuantityDialogState extends State<_PurchaseQuantityDialog> {
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
            if (quantity != null && quantity > 0) {
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

class _PriceDialog extends StatefulWidget {
  final Product product;
  final double defaultPrice;

  const _PriceDialog({
    required this.product,
    required this.defaultPrice,
  });

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultPrice.toString());
  }

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
          Text('Precio sugerido: ${Formatters.formatCurrency(widget.defaultPrice)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio unitario',
              prefixText: '\$ ',
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
            final price = double.tryParse(_controller.text);
            if (price != null && price >= 0) {
              Navigator.pop(context, price);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Precio inválido')),
              );
            }
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _SupplierSelectorDialog extends StatefulWidget {
  final List<Supplier> suppliers;

  const _SupplierSelectorDialog({required this.suppliers});

  @override
  State<_SupplierSelectorDialog> createState() => _SupplierSelectorDialogState();
}

class _SupplierSelectorDialogState extends State<_SupplierSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Supplier> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return widget.suppliers;
    return widget.suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (supplier.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Proveedor'),
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
              child: _filteredSuppliers.isEmpty
                  ? const Center(child: Text('No se encontraron proveedores'))
                  : ListView.builder(
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _filteredSuppliers[index];
                        return ListTile(
                          title: Text(supplier.name),
                          subtitle: supplier.phone != null ? Text(supplier.phone!) : null,
                          onTap: () => Navigator.pop(context, supplier),
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
