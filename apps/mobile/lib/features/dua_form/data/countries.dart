/// Country reference data for origin/destination pickers.
///
/// ISO 3166-1 alpha-3 codes (matches ATENA DUA field `paisOrigen` /
/// `paisDestino`). Ordered: Costa Rica first (for export defaults),
/// then Central America, then top global trade partners.
library;

import 'package:meta/meta.dart';

@immutable
class Country {
  /// ISO 3166-1 alpha-3.
  final String code;

  /// Spanish display name (DGA canonical spelling).
  final String name;

  const Country({required this.code, required this.name});
}

const List<Country> commonCountries = [
  // Costa Rica first — most exports originate here.
  Country(code: 'CRI', name: 'Costa Rica'),

  // CA-4 / SIECA neighbors.
  Country(code: 'GTM', name: 'Guatemala'),
  Country(code: 'SLV', name: 'El Salvador'),
  Country(code: 'HND', name: 'Honduras'),
  Country(code: 'NIC', name: 'Nicaragua'),
  Country(code: 'PAN', name: 'Panama'),

  // Top trade partners (2024 DGA rankings).
  Country(code: 'USA', name: 'Estados Unidos'),
  Country(code: 'MEX', name: 'Mexico'),
  Country(code: 'CHN', name: 'China'),
  Country(code: 'DEU', name: 'Alemania'),
  Country(code: 'NLD', name: 'Paises Bajos'),
  Country(code: 'BEL', name: 'Belgica'),
  Country(code: 'BRA', name: 'Brasil'),
  Country(code: 'COL', name: 'Colombia'),
  Country(code: 'DOM', name: 'Republica Dominicana'),
  Country(code: 'JPN', name: 'Japon'),
  Country(code: 'KOR', name: 'Corea del Sur'),
  Country(code: 'CAN', name: 'Canada'),
  Country(code: 'ESP', name: 'Espana'),
  Country(code: 'GBR', name: 'Reino Unido'),
  Country(code: 'FRA', name: 'Francia'),
  Country(code: 'ITA', name: 'Italia'),
];
