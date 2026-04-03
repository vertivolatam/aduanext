/// Value Object: Incoterm — International Commercial Terms 2020.
///
/// RIMM endpoint: /termsOfDelivery/search
/// Used in: shipping.deliveryTermsCode, invoices[].deliveryTermsCode
///
/// The responsibility matrix (who pays what) is critical for:
///   1. CIF value calculation (customs valuation base)
///   2. Risk transfer point determination
///   3. Insurance requirements
///   4. The Vetted Sourcers marketplace module
library;

import 'package:meta/meta.dart';

enum TransportMode { anyMode, seaAndInlandWaterway }

@immutable
class Incoterm {
  final String code;
  final String fullName;
  final TransportMode transportMode;

  /// Whether the seller is responsible for each obligation.
  final bool sellerExportClearance;
  final bool sellerMainCarriage;
  final bool sellerImportClearance;
  final bool sellerInsurance;
  final String riskTransferPoint;

  const Incoterm({
    required this.code,
    required this.fullName,
    required this.transportMode,
    required this.sellerExportClearance,
    required this.sellerMainCarriage,
    required this.sellerImportClearance,
    required this.sellerInsurance,
    required this.riskTransferPoint,
  });

  /// All 11 INCOTERM 2020 definitions.
  static const Map<String, Incoterm> all = {
    'EXW': Incoterm(code: 'EXW', fullName: 'Ex Works', transportMode: TransportMode.anyMode, sellerExportClearance: false, sellerMainCarriage: false, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: "Seller's premises"),
    'FCA': Incoterm(code: 'FCA', fullName: 'Free Carrier', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: false, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'Named place of delivery'),
    'CPT': Incoterm(code: 'CPT', fullName: 'Carriage Paid To', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'Carrier at origin'),
    'CIP': Incoterm(code: 'CIP', fullName: 'Carriage and Insurance Paid', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: true, riskTransferPoint: 'Carrier at origin'),
    'DAP': Incoterm(code: 'DAP', fullName: 'Delivered at Place', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'Named destination (not unloaded)'),
    'DPU': Incoterm(code: 'DPU', fullName: 'Delivered at Place Unloaded', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'Named destination (unloaded)'),
    'DDP': Incoterm(code: 'DDP', fullName: 'Delivered Duty Paid', transportMode: TransportMode.anyMode, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: true, sellerInsurance: false, riskTransferPoint: 'Named destination (all paid)'),
    'FAS': Incoterm(code: 'FAS', fullName: 'Free Alongside Ship', transportMode: TransportMode.seaAndInlandWaterway, sellerExportClearance: true, sellerMainCarriage: false, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'Alongside vessel at port'),
    'FOB': Incoterm(code: 'FOB', fullName: 'Free on Board', transportMode: TransportMode.seaAndInlandWaterway, sellerExportClearance: true, sellerMainCarriage: false, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'On board vessel'),
    'CFR': Incoterm(code: 'CFR', fullName: 'Cost and Freight', transportMode: TransportMode.seaAndInlandWaterway, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: false, riskTransferPoint: 'On board vessel'),
    'CIF': Incoterm(code: 'CIF', fullName: 'Cost, Insurance and Freight', transportMode: TransportMode.seaAndInlandWaterway, sellerExportClearance: true, sellerMainCarriage: true, sellerImportClearance: false, sellerInsurance: true, riskTransferPoint: 'On board vessel'),
  };

  static Incoterm fromCode(String code) => all[code.toUpperCase()]!;

  @override
  bool operator ==(Object other) => other is Incoterm && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Incoterm($code: $fullName)';
}
