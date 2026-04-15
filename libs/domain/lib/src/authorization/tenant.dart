/// Tenant — the outer isolation boundary for every piece of AduaNext data.
///
/// A Tenant is ONE of:
/// - an Agency (a customs brokerage firm employing multiple agents),
/// - a FreelanceAgent (a single licensed agent operating solo),
/// - an ImporterLed org (a pyme using the importer-led mode with a
///   contracted external agent as mandatory signer),
/// - an Educational org (a university using the sandbox for training).
///
/// Tenant-scoped data MUST never cross the tenant boundary. This is
/// enforced at three layers:
/// 1. application — handlers call `AuthorizationPort.requireTenant`;
/// 2. infrastructure — Postgres RLS policies key on `tenant_id`;
/// 3. audit — every [AuditEvent] carries a [tenantId] for forensics.
library;

import 'package:meta/meta.dart';

enum TenantType {
  agency,
  freelanceAgent,
  importerLed,
  educational,
}

@immutable
class Tenant {
  /// Stable, opaque identifier. Prefer UUIDs.
  final String id;

  final TenantType type;

  /// Legal name of the entity (as registered at the Registro Nacional).
  final String legalName;

  /// Tax identifier — `cedula juridica` for companies, `cedula fisica`
  /// for freelance agents. Kept as a raw string because Costa Rican
  /// tax IDs mix formats (digits, hyphens).
  final String taxId;

  const Tenant({
    required this.id,
    required this.type,
    required this.legalName,
    required this.taxId,
  });

  @override
  bool operator ==(Object other) =>
      other is Tenant &&
      other.id == id &&
      other.type == type &&
      other.legalName == legalName &&
      other.taxId == taxId;

  @override
  int get hashCode => Object.hash(id, type, legalName, taxId);

  @override
  String toString() => 'Tenant($id, $type, $legalName)';
}
