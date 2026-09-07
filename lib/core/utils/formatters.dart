import 'package:intl/intl.dart';

class Formatters {
  static final currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final currencyFormatterWithDecimals = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final dateFormatter = DateFormat('dd/MM/yyyy');
  static final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  static String formatCurrency(double value) {
    return currencyFormatter.format(value);
  }

  static String formatCurrencyWithDecimals(double value) {
    return currencyFormatterWithDecimals.format(value);
  }

  static String formatDate(DateTime date) {
    return dateFormatter.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormatter.format(dateTime);
  }
}
