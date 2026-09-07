import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/payment.dart';
import '../../core/constants/app_constants.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  PaymentRepository(this._dbHelper);

  Future<List<Payment>> getAllPayments() async {
    final data = await _dbHelper.query(
      AppConstants.paymentsTable,
      orderBy: 'date DESC',
    );
    return data.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByCustomer(String customerId) async {
    final data = await _dbHelper.query(
      AppConstants.paymentsTable,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return data.map((map) => Payment.fromMap(map)).toList();
  }

  Future<Payment?> getPaymentById(String id) async {
    final data = await _dbHelper.query(
      AppConstants.paymentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Payment.fromMap(data.first);
  }

  Future<Payment> createPayment(Payment payment) async {
    final newPayment = payment.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    await _dbHelper.insert(AppConstants.paymentsTable, newPayment.toMap());
    return newPayment;
  }

  Future<void> deletePayment(String id) async {
    await _dbHelper.delete(
      AppConstants.paymentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
