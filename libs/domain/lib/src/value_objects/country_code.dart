/// Value Object: Country Code — identifies which "hacienda" (customs authority) to use.
///
/// This is the discriminator for the multi-hacienda Adapter/Factory pattern.
/// Adding a new country means:
///   1. Add the enum value here
///   2. Create new Adapters in libs/adapters/{country}/
///   3. Register in CountryAdapterFactory
///   4. Add country-specific YAML config
///
/// No domain logic changes needed.
library;

enum CountryCode {
  /// Costa Rica — ATENA (Sistema Integrado de Administración Aduanera)
  CR('CR', 'Costa Rica', 'ATENA'),

  /// Guatemala — SAT-GT (Superintendencia de Administración Tributaria)
  GT('GT', 'Guatemala', 'SAT-GT'),

  /// Honduras — SARAH (Sistema Aduanero de Honduras)
  HN('HN', 'Honduras', 'SARAH'),

  /// El Salvador — SIDUNEA World
  SV('SV', 'El Salvador', 'SIDUNEA'),

  /// Nicaragua — SIDUNEA World
  NI('NI', 'Nicaragua', 'SIDUNEA'),

  /// Panamá — SIGA (Sistema Integrado de Gestión Aduanera)
  PA('PA', 'Panamá', 'SIGA'),

  /// República Dominicana — SIGA-RD
  DO('DO', 'República Dominicana', 'SIGA-RD');

  final String isoCode;
  final String name;
  final String customsSystemName;

  const CountryCode(this.isoCode, this.name, this.customsSystemName);

  static CountryCode fromIso(String iso) =>
      CountryCode.values.firstWhere((c) => c.isoCode == iso.toUpperCase());
}
