/// The 7 steps of the DUA preparation form.
///
/// Order matches SOP-B04 (Preparación DUA):
///   1. General      — exportador / consignatario / aduana
///   2. Envío        — incoterm / origen / destino / transporte
///   3. Items        — líneas de mercancía (con RIMM drawer inline)
///   4. Valoración   — factura, moneda, tipo de cambio, CIF
///   5. Facturas     — lista de facturas adjuntas
///   6. Documentos   — certificados, B/L, otros
///   7. Revisión     — pre-validación + submit
library;

enum DuaFormStep {
  general('General'),
  shipping('Envío'),
  items('Items'),
  valuation('Valoración'),
  invoices('Facturas'),
  documents('Documentos'),
  review('Revisión');

  final String displayName;
  const DuaFormStep(this.displayName);

  /// 1-based ordinal — used to render the numbered bubble in the
  /// stepper semáforo.
  int get ordinal => index + 1;

  /// Previous / next helpers so the page navigation doesn't need to
  /// touch the enum internals.
  DuaFormStep? get previous => index == 0 ? null : DuaFormStep.values[index - 1];
  DuaFormStep? get next =>
      index == DuaFormStep.values.length - 1 ? null : DuaFormStep.values[index + 1];
}

/// Semáforo tone for a given step — painted on the bubble + connector.
///
/// Drives the visual contract from the mockup
/// (`06-stepper-semaforo.html`):
///   * verde    — completado; clickeable.
///   * amarillo — incompleto o warning upstream.
///   * azul     — activo (en progreso).
///   * rojo     — pendiente / bloqueado (opacity 50%).
enum StepperTone {
  verde,
  amarillo,
  azul,
  rojo;
}
