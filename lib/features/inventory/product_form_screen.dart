import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/movement_provider.dart';
import '../../data/models/product.dart';
import '../../data/models/inventory_movement.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minStockController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _purchasePriceController.text = widget.product!.purchasePrice.toString();
      _salePriceController.text = widget.product!.salePrice.toString();
      _minStockController.text = widget.product!.minStock.toString();
    }
    
    // Agregar listeners para formatear precios mientras se escribe
    _purchasePriceController.addListener(_formatPurchasePrice);
    _salePriceController.addListener(_formatSalePrice);
  }

  void _formatPurchasePrice() {
    final text = _purchasePriceController.text;
    if (text.isEmpty) return;
    
    // Remover caracteres no numéricos excepto punto decimal
    final cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanText == _purchasePriceController.text) return;
    
    _purchasePriceController.value = _purchasePriceController.value.copyWith(
      text: cleanText,
      selection: TextSelection.collapsed(offset: cleanText.length),
    );
  }

  void _formatSalePrice() {
    final text = _salePriceController.text;
    if (text.isEmpty) return;
    
    // Remover caracteres no numéricos excepto punto decimal
    final cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanText == _salePriceController.text) return;
    
    _salePriceController.value = _salePriceController.value.copyWith(
      text: cleanText,
      selection: TextSelection.collapsed(offset: cleanText.length),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        quantity: int.parse(_quantityController.text),
        purchasePrice: double.parse(_purchasePriceController.text),
        salePrice: double.parse(_salePriceController.text),
        minStock: int.parse(_minStockController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.product == null) {
        // Create new product
        await ref.read(productListProvider.notifier).addProduct(product);
        
        // Register movement
        final movement = InventoryMovement(
          id: '',
          type: MovementType.productCreated,
          description: 'Producto creado: ${product.name}',
          date: DateTime.now(),
          amount: product.purchasePrice * product.quantity,
          relatedId: product.id,
          createdAt: DateTime.now(),
        );
        await ref.read(movementListProvider.notifier).addMovement(movement);
      } else {
        // Update existing product
        await ref.read(productListProvider.notifier).updateProduct(product);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Producto agregado exitosamente'
                : 'Producto actualizado exitosamente'),
          ),
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
        title: Text(widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                hintText: 'Ej. Licor de ron Santander 750 ml',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej. Bebida alcohólica en presentación de 750 ml',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      hintText: '0',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cantidad es requerida';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity < 0) {
                        return 'Ingrese un valor válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                      hintText: '0',
                      prefixIcon: Icon(Icons.minimize),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El stock mínimo es requerido';
                      }
                      final minStock = int.tryParse(value);
                      if (minStock == null || minStock < 0) {
                        return 'Ingrese un valor válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Precio de compra',
                hintText: '0.00',
                prefixIcon: Icon(Icons.shopping_cart),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio de compra es requerido';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salePriceController,
              decoration: const InputDecoration(
                labelText: 'Precio de venta',
                hintText: '0.00',
                prefixIcon: Icon(Icons.sell),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio de venta es requerido';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.product == null ? 'Agregar Producto' : 'Guardar Cambios',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
