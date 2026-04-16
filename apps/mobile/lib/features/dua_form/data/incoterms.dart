/// Incoterms 2020 reference data.
///
/// Source: ICC Incoterms 2020 rules. Codes match the ATENA DUA API
/// field `incoterm` (uppercase, 3 letters, no separators).
library;

import 'package:meta/meta.dart';

@immutable
class Incoterm {
  /// ICC 3-letter code (EXW, FCA, CIF, ...).
  final String code;

  /// Short English name.
  final String title;

  /// Transport modality applicability.
  ///   * 'any'      — works for any mode (EXW, FCA, CPT, CIP, DAP, DPU, DDP).
  ///   * 'sea'      — sea / inland waterway only (FAS, FOB, CFR, CIF).
  final String applicability;

  const Incoterm({
    required this.code,
    required this.title,
    required this.applicability,
  });
}

const List<Incoterm> incoterms2020 = [
  Incoterm(code: 'EXW', title: 'Ex Works', applicability: 'any'),
  Incoterm(code: 'FCA', title: 'Free Carrier', applicability: 'any'),
  Incoterm(code: 'CPT', title: 'Carriage Paid To', applicability: 'any'),
  Incoterm(code: 'CIP', title: 'Carriage and Insurance Paid to', applicability: 'any'),
  Incoterm(code: 'DAP', title: 'Delivered at Place', applicability: 'any'),
  Incoterm(code: 'DPU', title: 'Delivered at Place Unloaded', applicability: 'any'),
  Incoterm(code: 'DDP', title: 'Delivered Duty Paid', applicability: 'any'),
  Incoterm(code: 'FAS', title: 'Free Alongside Ship', applicability: 'sea'),
  Incoterm(code: 'FOB', title: 'Free On Board', applicability: 'sea'),
  Incoterm(code: 'CFR', title: 'Cost and Freight', applicability: 'sea'),
  Incoterm(code: 'CIF', title: 'Cost, Insurance and Freight', applicability: 'sea'),
];
