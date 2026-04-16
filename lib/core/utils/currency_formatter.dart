import 'package:intl/intl.dart';

final NumberFormat _inrCurrency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 2,
);

final NumberFormat _inrCurrencyNoDecimals = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 0,
);

final NumberFormat _inrCompactCurrency = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 1,
);

String formatCurrency(num amount) => _inrCurrency.format(amount);

String formatCurrencyNoDecimals(num amount) => _inrCurrencyNoDecimals.format(amount);

String formatCompactCurrency(num amount) => _inrCompactCurrency.format(amount);
