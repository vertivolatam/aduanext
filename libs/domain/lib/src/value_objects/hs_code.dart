/// Value Object: HS Code — Harmonized System tariff classification code.
///
/// Structure (Costa Rica / Central America SAC):
///   Positions 1-2:  Chapter (Capítulo)          — RIMM: /chapter/search
///   Positions 1-4:  Heading (Partida)            — RIMM: /heading/search
///   Positions 1-6:  Sub-heading (Sub-partida)    — RIMM: /subHeading/search (international HS)
///   Positions 1-8:  SAC code (Código S.A.)       — RIMM: /hsCode/search (Central American)
///   Positions 1-10: National code (Commodity)    — RIMM: /commodity/search (country-specific)
///   + up to 4 national precision levels (commodityCodeNationalPrecision2-4)
///
/// Example: 0901.11.0010 = Green coffee, Arabica, not roasted, SHB grade
///   Chapter: 09 (Coffee, tea, maté, spices)
///   Heading: 0901 (Coffee)
///   Sub-heading: 090111 (Not roasted, not decaffeinated)
///   SAC: 09011100 (Central American specificity)
///   National: 0901110010 (Costa Rica national precision)
library;

import 'package:meta/meta.dart';

@immutable
class HsCode {
  final String code;

  const HsCode(this.code);

  /// Validates that the code is at least 6 digits (international HS minimum).
  bool get isValid => RegExp(r'^\d{6,12}$').hasMatch(code);

  /// First 2 digits — Chapter level.
  String get chapter => code.substring(0, 2);

  /// First 4 digits — Heading level.
  String get heading => code.length >= 4 ? code.substring(0, 4) : code;

  /// First 6 digits — International HS sub-heading.
  String get subHeading => code.length >= 6 ? code.substring(0, 6) : code;

  /// First 8 digits — Central American SAC code.
  String? get sacCode => code.length >= 8 ? code.substring(0, 8) : null;

  /// Full code — up to 12 digits with national precision.
  String get fullCode => code;

  /// Formatted with dots: 0901.11.0010
  String get formatted {
    if (code.length <= 4) return code;
    final chapter = code.substring(0, 4);
    final rest = code.substring(4);
    if (rest.length <= 2) return '$chapter.$rest';
    final sub = rest.substring(0, 2);
    final national = rest.substring(2);
    return '$chapter.$sub.$national';
  }

  @override
  bool operator ==(Object other) => other is HsCode && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'HsCode($formatted)';
}
