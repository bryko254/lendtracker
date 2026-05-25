import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'en_KE',
  symbol: 'KSh ',
  decimalDigits: 2,
);

final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

String formatMoney(int minorUnits) {
  return _currencyFormatter.format(minorUnits / 100);
}

String formatDate(DateTime date) {
  return _dateFormatter.format(date);
}

int parseAmountToMinor(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (cleaned.isEmpty) {
    return 0;
  }
  final value = double.tryParse(cleaned) ?? 0;
  return (value * 100).round();
}
