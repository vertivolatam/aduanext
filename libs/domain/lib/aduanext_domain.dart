/// AduaNext Domain Layer — pure business logic with zero I/O dependencies.
///
/// Barrel file exposing the public API of the domain package.
library;

// Ports (interfaces implemented by adapters).
export 'src/ports/audit_log_port.dart';
export 'src/ports/auth_provider_port.dart';
export 'src/ports/authorization_port.dart';
export 'src/ports/customs_gateway_port.dart';
export 'src/ports/legal_hold_port.dart';
export 'src/ports/notification_port.dart';
export 'src/ports/pkcs11_signing_port.dart';
export 'src/ports/retention_purgeable_port.dart';
export 'src/ports/signing_port.dart';
export 'src/ports/storage_backend_port.dart';
export 'src/ports/tariff_catalog_port.dart';

// Retention.
export 'src/retention/legal_hold.dart';
export 'src/retention/retention_policy.dart';

// Entities.
export 'src/entities/agent_profile.dart';
export 'src/entities/classification_decision.dart';
export 'src/entities/declaration.dart';

// Authorization entities + value objects.
export 'src/authorization/role.dart';
export 'src/authorization/tenant.dart';
export 'src/authorization/tenant_membership.dart';
export 'src/authorization/user.dart';

// Value Objects.
export 'src/value_objects/country_code.dart';
export 'src/value_objects/declaration_status.dart';
export 'src/value_objects/hs_code.dart';
export 'src/value_objects/incoterm.dart';
