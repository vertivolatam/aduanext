/// Parses a validated Keycloak JWT claim map into AduaNext domain values
/// ([User], [TenantMembership], [Role]).
///
/// Keycloak emits claims through a custom mapper defined in the `aduanext`
/// realm (see infrastructure/keycloak/README.md):
///
///   `sub`                       → `String` (stable user id)
///   `email`                     → `String`
///   `aduanext_tenant_ids`       → `List<String>` (tenant ids the user belongs to)
///   `aduanext_roles`            → `Map<String, List<String>>` keyed by tenant id
///   `aduanext_membership_since` → `Map<String, String>` ISO-8601 per tenant
///   `aduanext_membership_exp`   → `Map<String, String>` ISO-8601 per tenant
///                                 (missing entries mean open-ended)
///
/// A malformed token (missing required claims, unknown role) raises
/// [MalformedTokenException] — distinct from signature / expiry failures
/// which are raised by the adapter BEFORE this code runs.
library;

import 'package:aduanext_domain/aduanext_domain.dart';

/// Thrown when a JWT's signature + expiry were valid but its payload
/// does not expose the claims AduaNext requires.
class MalformedTokenException implements Exception {
  final String message;
  const MalformedTokenException(this.message);
  @override
  String toString() => 'MalformedTokenException: $message';
}

/// Pure mapper — no I/O.
class KeycloakClaimsMapper {
  const KeycloakClaimsMapper();

  /// Convert [claims] (already signature-verified) into a [User].
  ///
  /// Memberships with `since` > [now] or expired before [now] ARE still
  /// included in the returned [User.memberships] set — the final
  /// active-at-now filter is the responsibility of
  /// [User.activeMembershipsAt] / [AuthorizationPort]. This keeps the
  /// mapper pure and matches the InMemory adapter's contract.
  User toUser(Map<String, dynamic> claims) {
    final sub = _stringClaim(claims, 'sub');
    final email = _stringClaim(claims, 'email');

    final tenantIds = _stringListClaim(claims, 'aduanext_tenant_ids');
    final rolesClaim = _mapListClaim(claims, 'aduanext_roles');
    final sinceClaim = _mapStringClaim(claims, 'aduanext_membership_since');
    final expClaim = _mapStringClaim(
      claims,
      'aduanext_membership_exp',
      optional: true,
    );

    final memberships = <TenantMembership>{};
    for (final tenantId in tenantIds) {
      final roleCodes = rolesClaim[tenantId];
      if (roleCodes == null || roleCodes.isEmpty) {
        throw MalformedTokenException(
          'aduanext_roles missing entry for tenant "$tenantId"',
        );
      }
      // Use the highest role if more than one is assigned (Keycloak allows
      // multiple client roles per user; we collapse to the max rank).
      Role? highest;
      for (final code in roleCodes) {
        final parsed = Role.fromCode(code);
        if (parsed == null) continue;
        if (highest == null || parsed.outranks(highest)) highest = parsed;
      }
      if (highest == null) {
        throw MalformedTokenException(
          'aduanext_roles for tenant "$tenantId" had no recognised role '
          '(got ${roleCodes.join(', ')})',
        );
      }
      final sinceRaw = sinceClaim[tenantId];
      if (sinceRaw == null) {
        throw MalformedTokenException(
          'aduanext_membership_since missing entry for tenant "$tenantId"',
        );
      }
      final since = _parseDate(
        sinceRaw,
        'aduanext_membership_since[$tenantId]',
      );
      final expRaw = expClaim[tenantId];
      final expires = expRaw == null
          ? null
          : _parseDate(expRaw, 'aduanext_membership_exp[$tenantId]');
      memberships.add(
        TenantMembership(
          userId: sub,
          tenantId: tenantId,
          role: highest,
          since: since,
          expires: expires,
        ),
      );
    }

    return User(
      id: sub,
      email: email,
      memberships: memberships,
      authProvider: UserAuthProvider.keycloak,
    );
  }

  // --- claim helpers (defensive parsers) ---------------------------------

  String _stringClaim(Map<String, dynamic> claims, String key) {
    final v = claims[key];
    if (v is! String || v.isEmpty) {
      throw MalformedTokenException('Missing or empty string claim "$key"');
    }
    return v;
  }

  List<String> _stringListClaim(Map<String, dynamic> claims, String key) {
    final v = claims[key];
    if (v == null) {
      throw MalformedTokenException('Missing list claim "$key"');
    }
    if (v is! List) {
      throw MalformedTokenException('Claim "$key" is not a JSON array');
    }
    return v.map((e) {
      if (e is! String) {
        throw MalformedTokenException(
          'Claim "$key" entry is not a string: $e',
        );
      }
      return e;
    }).toList(growable: false);
  }

  Map<String, List<String>> _mapListClaim(
    Map<String, dynamic> claims,
    String key,
  ) {
    final v = claims[key];
    if (v == null) {
      throw MalformedTokenException('Missing map claim "$key"');
    }
    if (v is! Map) {
      throw MalformedTokenException('Claim "$key" is not a JSON object');
    }
    final out = <String, List<String>>{};
    v.forEach((k, val) {
      if (k is! String) return;
      if (val is! List) {
        throw MalformedTokenException(
          'Claim "$key.$k" is not a JSON array',
        );
      }
      out[k] = val
          .map((e) => e is String ? e : throw MalformedTokenException(
                'Claim "$key.$k" contained non-string entry',
              ))
          .toList(growable: false);
    });
    return out;
  }

  Map<String, String> _mapStringClaim(
    Map<String, dynamic> claims,
    String key, {
    bool optional = false,
  }) {
    final v = claims[key];
    if (v == null) {
      if (optional) return const {};
      throw MalformedTokenException('Missing map claim "$key"');
    }
    if (v is! Map) {
      throw MalformedTokenException('Claim "$key" is not a JSON object');
    }
    final out = <String, String>{};
    v.forEach((k, val) {
      if (k is! String) return;
      if (val is! String) {
        throw MalformedTokenException(
          'Claim "$key.$k" is not a string',
        );
      }
      out[k] = val;
    });
    return out;
  }

  DateTime _parseDate(String raw, String where) {
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      throw MalformedTokenException(
        '$where is not a valid ISO-8601 timestamp (got "$raw")',
      );
    }
  }
}
