/// Costa Rica customs offices (aduanas) reference data.
///
/// Hardcoded top-10 for the MVP — VRTV-88 scope only fills the form,
/// real RIMM catalogue lookup lands later. Codes match the ATENA
/// DUA API field `codigoAduana`.
library;

import 'package:meta/meta.dart';

@immutable
class CustomsOffice {
  /// 3-digit code per SIAA-ATENA spec.
  final String code;

  /// Display name in Spanish (exact wording from ATENA catalog).
  final String name;

  /// Region hint — used by the picker to group offices.
  final String region;

  const CustomsOffice({
    required this.code,
    required this.name,
    required this.region,
  });
}

/// Top-10 Costa Rica customs offices. Ordered by transactional volume
/// (per DGA 2024 annual report) so the most common pick bubbles first.
const List<CustomsOffice> crCustomsOffices = [
  CustomsOffice(code: '001', name: 'Aduana Central', region: 'San Jose'),
  CustomsOffice(code: '002', name: 'Aduana Limon', region: 'Caribe'),
  CustomsOffice(code: '003', name: 'Aduana Caldera', region: 'Pacifico'),
  CustomsOffice(code: '004', name: 'Aduana Santa Rosa', region: 'Norte'),
  CustomsOffice(code: '005', name: 'Aduana Penas Blancas', region: 'Norte'),
  CustomsOffice(code: '006', name: 'Aduana Paso Canoas', region: 'Sur'),
  CustomsOffice(code: '007', name: 'Aduana Sabalito', region: 'Sur'),
  CustomsOffice(code: '008', name: 'Aduana Aeropuerto Juan Santamaria', region: 'Alajuela'),
  CustomsOffice(code: '009', name: 'Aduana Postal', region: 'San Jose'),
  CustomsOffice(code: '010', name: 'Aduana Golfito', region: 'Sur'),
];
