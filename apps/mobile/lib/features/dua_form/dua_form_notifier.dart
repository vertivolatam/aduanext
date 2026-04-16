/// State holder for the DUA form.
///
/// Responsibilities:
///   * Own the `DuaDraft` instance and expose `copyWith`-style
///     mutators that the per-step widgets call on user input.
///   * Persist the draft to [DuaDraftStore] on a 30-second cadence
///     (and every manual Guardar click).
///   * Compute the stepper tone for each of the 7 steps (verde /
///     amarillo / azul / rojo).
///
/// Subclasses `StateNotifier<DuaDraft>` so widgets can `watch` the
/// draft and rebuild only on the slots they care about (e.g. Step
/// 1's exporter picker watches `exporterCode`, not the full draft).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'draft_store.dart';
import 'dua_form_state.dart';
import 'steps.dart';

/// 30-second autosave cadence per the parent issue scope.
const Duration _autosaveInterval = Duration(seconds: 30);

class DuaFormNotifier extends StateNotifier<DuaDraft> {
  final DuaDraftStore _store;
  final DateTime Function() _now;
  final Uuid _uuid;

  Timer? _autosaveTimer;

  DuaFormNotifier({
    required DuaDraftStore store,
    DateTime Function()? now,
    Uuid? uuid,
  })  : _store = store,
        _now = now ?? DateTime.now,
        _uuid = uuid ?? const Uuid(),
        super(
          DuaDraft.fresh(
            draftId: (uuid ?? const Uuid()).v4(),
            now: (now ?? DateTime.now)(),
          ),
        ) {
    _autosaveTimer = Timer.periodic(_autosaveInterval, (_) => _persist());
  }

  /// Loads an existing draft from storage, if one exists. Called by
  /// the provider init so the form resumes after a browser refresh.
  Future<void> restore() async {
    final stored = await _store.load();
    if (stored != null) {
      state = stored;
    }
  }

  /// Reset the draft — typically called from "Nueva DUA" after a
  /// successful submit. Clears the persistent store too.
  Future<void> resetToFresh() async {
    await _store.clear();
    state = DuaDraft.fresh(draftId: _uuid.v4(), now: _now());
  }

  /// Jump to a specific step. No-op if the target is locked (the
  /// stepper semáforo greys out bubbles that aren't reachable yet).
  void goToStep(DuaFormStep step) {
    if (!state.isStepUnlocked(step)) return;
    _mutate(state.copyWith(currentStep: step));
  }

  void goNext() {
    final next = state.currentStep.next;
    if (next == null) return;
    if (!state.isStepUnlocked(next)) return;
    goToStep(next);
  }

  void goPrev() {
    final prev = state.currentStep.previous;
    if (prev == null) return;
    goToStep(prev);
  }

  // ─── Per-field mutators ─────────────────────────────────────────

  void setGeneral({
    String? exporterCode,
    String? exporterName,
    String? customsOfficeCode,
  }) {
    _mutate(state.copyWith(
      exporterCode: exporterCode,
      exporterName: exporterName,
      customsOfficeCode: customsOfficeCode,
    ));
  }

  void setShipping({
    String? incotermCode,
    String? countryOfOriginCode,
    String? countryOfDestinationCode,
    String? transportModeCode,
  }) {
    _mutate(state.copyWith(
      incotermCode: incotermCode,
      countryOfOriginCode: countryOfOriginCode,
      countryOfDestinationCode: countryOfDestinationCode,
      transportModeCode: transportModeCode,
    ));
  }

  void addItem(DuaDraftLineItem item) {
    _mutate(state.copyWith(items: [...state.items, item]));
  }

  void updateItem(int index, DuaDraftLineItem item) {
    if (index < 0 || index >= state.items.length) return;
    final next = [...state.items];
    next[index] = item;
    _mutate(state.copyWith(items: next));
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final next = [...state.items]..removeAt(index);
    _mutate(state.copyWith(items: next));
  }

  // ─── Step 4 — Valoración ─────────────────────────────────────

  void setValuation({
    String? invoiceCurrencyCode,
    double? exchangeRate,
    double? freightAmount,
    double? insuranceAmount,
  }) {
    _mutate(state.copyWith(
      invoiceCurrencyCode: invoiceCurrencyCode,
      exchangeRate: exchangeRate,
      freightAmount: freightAmount,
      insuranceAmount: insuranceAmount,
    ));
  }

  // ─── Step 5 — Facturas ───────────────────────────────────────

  void addInvoice([DuaDraftInvoice invoice = const DuaDraftInvoice()]) {
    _mutate(state.copyWith(invoices: [...state.invoices, invoice]));
  }

  void updateInvoice(int index, DuaDraftInvoice invoice) {
    if (index < 0 || index >= state.invoices.length) return;
    final next = [...state.invoices];
    next[index] = invoice;
    _mutate(state.copyWith(invoices: next));
  }

  void removeInvoice(int index) {
    if (index < 0 || index >= state.invoices.length) return;
    final next = [...state.invoices]..removeAt(index);
    _mutate(state.copyWith(invoices: next));
  }

  // ─── Step 6 — Documentos ─────────────────────────────────────

  /// Seed the checklist with the required docs for the current regimen.
  /// Idempotent — no-op if the list already has entries.
  void seedDocumentsIfEmpty(List<DuaDraftDocument> required) {
    if (state.documents.isNotEmpty) return;
    _mutate(state.copyWith(documents: required));
  }

  void updateDocument(int index, DuaDraftDocument document) {
    if (index < 0 || index >= state.documents.length) return;
    final next = [...state.documents];
    next[index] = document;
    _mutate(state.copyWith(documents: next));
  }

  void addDocument(DuaDraftDocument document) {
    _mutate(state.copyWith(documents: [...state.documents, document]));
  }

  void removeDocument(int index) {
    if (index < 0 || index >= state.documents.length) return;
    final next = [...state.documents]..removeAt(index);
    _mutate(state.copyWith(documents: next));
  }

  // ─── Stepper tone ──────────────────────────────────────────────

  StepperTone toneFor(DuaFormStep step) {
    final active = step == state.currentStep;
    final complete = state.isStepComplete(step);
    final unlocked = state.isStepUnlocked(step);

    if (!unlocked) return StepperTone.rojo;
    if (active) return StepperTone.azul;
    if (complete) return StepperTone.verde;
    // Past step that isn't complete — warning.
    if (step.index < state.currentStep.index) return StepperTone.amarillo;
    return StepperTone.amarillo;
  }

  // ─── Persistence ───────────────────────────────────────────────

  /// Manual save — surfaces a success state via `savedAt`.
  Future<void> persistNow() async {
    await _persist();
  }

  Future<void> _persist() async {
    final snapshot = state.copyWith(savedAt: _now());
    state = snapshot;
    await _store.save(snapshot);
  }

  void _mutate(DuaDraft next) {
    state = next.copyWith(updatedAt: _now());
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    super.dispose();
  }
}

/// The [DuaDraftStore] provider. Overridden in tests with an
/// [InMemoryDraftStore] instance.
final duaDraftStoreProvider = Provider<DuaDraftStore>((ref) {
  return SharedPrefsDraftStore();
});

/// Singleton notifier driving the form. `autoDispose` is avoided —
/// the draft survives page navigation (e.g. the agent opens another
/// tab and comes back).
final duaFormProvider =
    StateNotifierProvider<DuaFormNotifier, DuaDraft>((ref) {
  final store = ref.watch(duaDraftStoreProvider);
  final notifier = DuaFormNotifier(store: store);
  // Kick off restore — if a draft exists in storage, replace state.
  unawaited(notifier.restore());
  return notifier;
});
