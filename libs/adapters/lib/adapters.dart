/// AduaNext Secondary Adapters — gRPC-based implementations of domain Ports.
///
/// Provides adapters for:
/// - **AtenaAuthAdapter** — Authentication via hacienda-sidecar (OIDC ROPC)
/// - **AtenaCustomsGatewayAdapter** — DUA operations via hacienda-sidecar
/// - **HaciendaSigningAdapter** — XAdES-EPES signing via hacienda-sidecar
/// - **RimmTariffCatalogAdapter** — Tariff/HS code lookups via RIMM
/// - **GrpcChannelManager** — Shared gRPC channel lifecycle management
library;

export 'src/adapters.dart';
