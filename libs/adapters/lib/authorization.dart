/// Authorization adapters implementing [AuthorizationPort].
///
/// * [InMemoryAuthorizationAdapter] — for tests and local-dev runs.
///   The production [KeycloakAuthorizationAdapter] ships in follow-up
///   sub-issue VRTV-55b.
library;

export 'src/authorization/in_memory_authorization_adapter.dart';
