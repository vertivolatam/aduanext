/// Invoice currency reference data.
///
/// ISO 4217 — top global trade currencies. RIMM exchange rates are
/// published for USD/EUR/JPY daily; CRC is the local reference.
library;

import 'package:meta/meta.dart';

@immutable
class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const List<Currency> invoiceCurrencies = [
  Currency(code: 'USD', name: 'Dolar estadounidense', symbol: '\$'),
  Currency(code: 'EUR', name: 'Euro', symbol: '€'),
  Currency(code: 'CRC', name: 'Colon costarricense', symbol: '₡'),
  Currency(code: 'CNY', name: 'Yuan chino', symbol: '¥'),
  Currency(code: 'MXN', name: 'Peso mexicano', symbol: '\$'),
  Currency(code: 'JPY', name: 'Yen japones', symbol: '¥'),
  Currency(code: 'GBP', name: 'Libra esterlina', symbol: '£'),
  Currency(code: 'CAD', name: 'Dolar canadiense', symbol: '\$'),
];
