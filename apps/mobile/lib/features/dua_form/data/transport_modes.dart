/// Transport modes reference data.
///
/// Single-digit codes from ATENA DUA field `codigoMedioTransporte`.
/// Covers the modes actually used in Costa Rica customs flow.
library;

import 'package:meta/meta.dart';

@immutable
class TransportMode {
  /// 1-digit code from the ATENA catalog.
  final String code;

  /// Spanish display label.
  final String label;

  /// Material icon codepoint alias — used by the picker chip.
  final String iconName;

  const TransportMode({
    required this.code,
    required this.label,
    required this.iconName,
  });
}

const List<TransportMode> transportModes = [
  TransportMode(code: '1', label: 'Maritimo', iconName: 'directions_boat'),
  TransportMode(code: '2', label: 'Ferroviario', iconName: 'train'),
  TransportMode(code: '3', label: 'Carretera', iconName: 'local_shipping'),
  TransportMode(code: '4', label: 'Aereo', iconName: 'flight'),
  TransportMode(code: '5', label: 'Postal', iconName: 'local_post_office'),
  TransportMode(code: '7', label: 'Instalacion fija', iconName: 'factory'),
  TransportMode(code: '8', label: 'Via navegacion interior', iconName: 'waves'),
  TransportMode(code: '9', label: 'Propia propulsion', iconName: 'agriculture'),
];
