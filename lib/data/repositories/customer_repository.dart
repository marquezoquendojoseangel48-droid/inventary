import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/customer.dart';
import '../../core/constants/app_constants.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  CustomerRepository(this._dbHelper);

  Future<List<Customer>> getAllCustomers() async {
    final data = await _dbHelper.query(
      AppConstants.customersTable,
      orderBy: 'name ASC',
    );
    return data.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Customer.fromMap(data.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final data = await _dbHelper.query(
      AppConstants.customersTable,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return data.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> getCustomersWithPendingBalance() async {
    final data = await _dbHelper.query(
      AppConstants.customersTable,
      where: 'pendingBalance > 0',
      orderBy: 'name ASC',
    );
    return data.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final newCustomer = customer.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingBalance: customer.pendingBalance,
    );
    await _dbHelper.insert(AppConstants.customersTable, newCustomer.toMap());
    return newCustomer;
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final updatedCustomer = customer.copyWith(
      updatedAt: DateTime.now(),
    );
    await _dbHelper.update(
      AppConstants.customersTable,
      updatedCustomer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return updatedCustomer;
  }

  Future<void> deleteCustomer(String id) async {
    await _dbHelper.delete(
      AppConstants.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePendingBalance(String customerId, double amount) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    final newBalance = customer.pendingBalance + amount;
    if (newBalance < 0) {
      throw Exception('El pago no puede superar el saldo pendiente');
    }

    await updateCustomer(customer.copyWith(pendingBalance: newBalance));
  }

  Future<double> getTotalPendingBalance() async {
    final customers = await getAllCustomers();
    return customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.pendingBalance,
    );
  }
}
