/// AduaNext primary server — HTTP boundary that wires domain Ports to
/// concrete adapters from `libs/adapters`.
///
/// Public API:
/// * [ServerConfig] — runtime configuration from environment variables.
/// * [AppContainer] — constructs the 4 gRPC adapters + audit log, and
///   owns their lifecycle.
/// * [buildHandler] — shelf [Handler] with the `/livez` and `/readyz`
///   probes. Will grow with subsequent issues.
library;

export 'src/config/retention_config.dart';
export 'src/di/container.dart';
export 'src/di/server_config.dart';
export 'src/http/dispatch_endpoints.dart';
export 'src/http/dispatch_payload.dart';
export 'src/http/error_mapping.dart';
export 'src/http/error_responses.dart';
export 'src/http/handler.dart';
export 'src/http/health_endpoint.dart';
export 'src/http/request_context.dart';
export 'src/http/routes.dart';
export 'src/middleware/auth_middleware.dart';
export 'src/middleware/rate_limiter.dart';
export 'src/middleware/role_guard.dart';
export 'src/workers/retention_worker.dart';
