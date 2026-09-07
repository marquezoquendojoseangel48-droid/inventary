import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/movement_provider.dart';
import '../../data/models/payment.dart';
import '../../data/models/customer.dart';
import '../../data/models/inventory_movement.dart';
import '../../core/utils/formatters.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _registerPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount > _selectedCustomer!.pendingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El pago no puede superar el saldo pendiente')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = Payment(
        id: '',
        customerId: _selectedCustomer!.id,
        amount: amount,
        date: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Create payment
      await ref.read(paymentListProvider.notifier).addPayment(payment);

      // Update customer balance
      await ref.read(customerListProvider.notifier).updatePendingBalance(
            _selectedCustomer!.id,
            -amount,
          );

      // Register movement
      final movement = InventoryMovement(
        id: '',
        type: MovementType.payment,
        description: 'Pago de ${_selectedCustomer!.name}',
        date: DateTime.now(),
        amount: amount,
        relatedId: payment.id,
        createdAt: DateTime.now(),
      );
      await ref.read(movementListProvider.notifier).addMovement(movement);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado exitosamente')),
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
        title: const Text('Registrar Pago'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  _selectedCustomer?.name ?? 'Seleccionar Cliente',
                ),
                subtitle: _selectedCustomer != null
                    ? Text('Saldo pendiente: ${Formatters.formatCurrency(_selectedCustomer!.pendingBalance)}')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectCustomer,
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto del pago',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El monto es requerido';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingrese un monto válido';
                }
                if (_selectedCustomer != null && amount > _selectedCustomer!.pendingBalance) {
                  return 'El pago no puede superar el saldo pendiente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Agrega notas sobre este pago',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _registerPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Registrar Pago',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
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
    final customersWithBalance = widget.customers.where((c) => c.pendingBalance > 0).toList();
    
    if (_searchQuery.isEmpty) return customersWithBalance;
    return customersWithBalance.where((customer) {
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
                  ? const Center(child: Text('No se encontraron clientes con saldo pendiente'))
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(
                            'Saldo pendiente: ${Formatters.formatCurrency(customer.pendingBalance)}',
                          ),
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
      ],
    );
  }
}
