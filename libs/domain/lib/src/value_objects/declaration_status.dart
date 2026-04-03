/// Value Object: Declaration Status — maps the ATENA state machine.
///
/// Based on official DGA Export Procedures Manual (Oct 2025),
/// Section 6.4, activities 6.4.1 through 6.4.52.
///
/// ATENA status codes observed in API responses:
///   "ST_ASSESSED" — Liquidated/assessed
///   "TO_BE_PAID" — Payment pending
///   Other codes TBD from actual API interaction
library;

enum DeclarationStatus {
  /// Created locally in AduaNext, not yet sent to ATENA.
  draft('DRAFT', 'Borrador'),

  /// Registered in ATENA, pending validation.
  registered('REGISTERED', 'Registrada'),

  /// ATENA is validating (tariff, valuation, documents).
  validating('VALIDATING', 'En validación'),

  /// Validated by ATENA, pending payment.
  paymentPending('PAYMENT_PENDING', 'Pendiente de pago'),

  /// Payment confirmed. DUA accepted (activity 6.4.14).
  accepted('ACCEPTED', 'Aceptada'),

  /// Waiting for LPCO (notas técnicas). 5-day deadline (activity 6.4.15).
  lpcoPending('LPCO_PENDING', 'LPCO pendiente'),

  /// Auto-annulled because LPCO deadline expired (activity 6.4.16).
  annulled('ANNULLED', 'Anulada'),

  /// Risk selectivity applied. No review needed (activity 6.4.18 note 2).
  levante('LEVANTE', 'Levante autorizado'),

  /// Levante in transit — goods can move to port (activity 6.4.21).
  levanteTransit('LEVANTE_TRANSIT', 'Levante en tránsito'),

  /// DUCA-F sent to SIECA automatically (activity 6.4.19).
  ducaSentToSieca('DUCA_SENT_TO_SIECA', 'DUCA-F enviada a SIECA'),

  /// Document review assigned (risk selectivity: documental).
  documentReview('DOCUMENT_REVIEW', 'Revisión documental'),

  /// Physical inspection assigned (risk selectivity: documental + physical).
  physicalInspection('PHYSICAL_INSPECTION', 'Revisión documental y reconocimiento físico'),

  /// T1 mobilization control registered (section 6.5).
  t1Mobilization('T1_MOBILIZATION', 'Control de movilización T1'),

  /// Arrived at port — COARRI validation for containers (activity 6.4.32).
  arrivedAtPort('ARRIVED_AT_PORT', 'Levante arribado'),

  /// All containers/packages have departed (activity 6.4.33).
  departureFull('DEPARTURE_FULL', 'Levante salida total'),

  /// Partial departure — some containers/packages still pending (activity 6.4.34).
  departurePartial('DEPARTURE_PARTIAL', 'Levante salida parcial'),

  /// 10-day confirmation window active (activity 6.4.35).
  confirmationWindow('CONFIRMATION_WINDOW', 'Ventana de confirmación'),

  /// Confirmed — auto (activity 6.4.36) or manual via boletín (activity 6.4.37).
  confirmed('CONFIRMED', 'Confirmada'),

  /// Final verification passed (activity 6.4.45-6.4.52).
  finalConfirmed('FINAL_CONFIRMED', 'Confirmada definitiva'),

  /// Rejected by ATENA — requires correction.
  rejected('REJECTED', 'Rechazada'),

  /// Cancelled by declarant.
  cancelled('CANCELLED', 'Cancelada');

  final String code;
  final String displayName;

  const DeclarationStatus(this.code, this.displayName);

  static DeclarationStatus fromCode(String code) =>
      DeclarationStatus.values.firstWhere((s) => s.code == code);

  /// Whether this status allows modifications via contra-escritura.
  bool get allowsContraEscritura => switch (this) {
    accepted || levante || levanteTransit || arrivedAtPort ||
    departureFull || departurePartial || confirmationWindow => true,
    _ => false,
  };

  /// Whether this status triggers a notification.
  bool get triggersNotification => switch (this) {
    accepted || rejected || levante || documentReview ||
    physicalInspection || departureFull || confirmed || annulled => true,
    _ => false,
  };
}
