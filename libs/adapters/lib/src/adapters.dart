/// Barrel export for all AduaNext secondary adapters.
///
/// Usage:
/// ```dart
/// import 'package:aduanext_adapters/adapters.dart';
/// ```
library;

// gRPC infrastructure
export 'grpc/grpc_channel_manager.dart';

// ATENA adapters (Costa Rica customs authority)
export 'atena/atena_auth_adapter.dart';
export 'atena/atena_customs_gateway_adapter.dart';

// Digital signing
export 'signing/hacienda_signing_adapter.dart';

// RIMM tariff catalog
export 'rimm/rimm_tariff_catalog_adapter.dart';
