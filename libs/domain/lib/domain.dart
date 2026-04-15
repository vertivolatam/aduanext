/// AduaNext Domain Layer — Pure business logic.
///
/// Entities, Value Objects, Ports (interfaces), and Domain Services.
/// Zero I/O dependencies.
library;

// Entities
export 'src/entities/declaration.dart';

// Value Objects
export 'src/value_objects/declaration_status.dart';
export 'src/value_objects/hs_code.dart';

// Ports (interfaces for adapters to implement)
export 'src/ports/auth_provider_port.dart';
export 'src/ports/authorization_port.dart';
export 'src/ports/customs_gateway_port.dart';
export 'src/ports/signing_port.dart';
export 'src/ports/tariff_catalog_port.dart';
export 'src/ports/audit_log_port.dart';
export 'src/ports/notification_port.dart';

// Authorization entities + value objects.
export 'src/authorization/role.dart';
export 'src/authorization/tenant.dart';
export 'src/authorization/tenant_membership.dart';
export 'src/authorization/user.dart';
