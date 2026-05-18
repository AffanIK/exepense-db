import 'package:intl/intl.dart';

final _pkr2 = NumberFormat.currency(
  locale: 'en_US',
  symbol: 'PKR ',
  decimalDigits: 2,
);
final _pkr0 = NumberFormat.currency(
  locale: 'en_US',
  symbol: 'PKR ',
  decimalDigits: 0,
);

/// Format a number as PKR with 2 decimals (e.g. "PKR 1,500.00").
/// Negative balances render with a minus prefix: "−PKR 200.00".
String formatPkr(num value, {int decimals = 2}) {
  final f = decimals == 0 ? _pkr0 : _pkr2;
  if (value < 0) return '−${f.format(value.abs())}';
  return f.format(value);
}

/// Like [formatPkr] but always with a leading minus, used for expense rows.
String formatExpense(num value, {int decimals = 2}) {
  final f = decimals == 0 ? _pkr0 : _pkr2;
  return '−${f.format(value.abs())}';
}
