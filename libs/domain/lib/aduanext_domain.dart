/// AduaNext Domain Layer — pure business logic with zero I/O dependencies.
///
/// Barrel file exposing the public API of the domain package.
library;

// Ports (interfaces implemented by adapters).
export 'src/ports/audit_log_port.dart';
export 'src/ports/auth_provider_port.dart';
export 'src/ports/customs_gateway_port.dart';
export 'src/ports/notification_port.dart';
export 'src/ports/signing_port.dart';
export 'src/ports/tariff_catalog_port.dart';

// Entities.
export 'src/entities/classification_decision.dart';
export 'src/entities/declaration.dart';

// Value Objects.
export 'src/value_objects/country_code.dart';
export 'src/value_objects/declaration_status.dart';
export 'src/value_objects/hs_code.dart';
export 'src/value_objects/incoterm.dart';
