/// Tests for [TransitionDeclarationStatusHandler] — the use case that
/// drives the declaration state machine.
///
/// We use the in-memory repository + dispatcher + audit adapters to
/// exercise the full choreography without any I/O.
library;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_adapters/notifications.dart';
import 'package:aduanext_adapters/persistence.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('TransitionDeclarationStatusHandler', () {
    late InMemoryAuditLogAdapter auditLog;
    late InMemoryDeclarationRepositoryAdapter repo;
    late InMemoryNotificationDispatcherAdapter dispatcher;
    late TransitionDeclarationStatusHandler handler;

    final fixedNow = DateTime.utc(2026, 4, 16, 12, 0, 0);
    var nextId = 0;

    setUp(() {
      auditLog = InMemoryAuditLogAdapter(now: () => fixedNow);
      repo = InMemoryDeclarationRepositoryAdapter();
      dispatcher = InMemoryNotificationDispatcherAdapter();
      nextId = 0;
      handler = TransitionDeclarationStatusHandler(
        repository: repo,
        auditLog: auditLog,
        notifications: dispatcher,
        clock: () => fixedNow,
        idGenerator: () => 'evt-${++nextId}',
      );
    });

    test('returns failure for an empty declarationId', () async {
      final result = await handler.handle(
        TransitionDeclarationStatusCommand(
          declarationId: '',
          tenantId: 'tenant-1',
          toStatus: DeclarationStatus.registered,
          trigger: TransitionTrigger.gateway,
          actorId: 'atena-gateway',
        ),
      );
      expect(result.isErr, isTrue);
    });

    test('returns DeclarationNotFoundFailure when the id is unknown',
        () async {
      final result = await handler.handle(
        TransitionDeclarationStatusCommand(
          declarationId: 'MISSING',
          tenantId: 'tenant-1',
          toStatus: DeclarationStatus.registered,
          trigger: TransitionTrigger.gateway,
          actorId: 'atena-gateway',
        ),
      );
      expect(result.isErr, isTrue);
      expect((result as Err<DeclarationStatus>).failure,
          isA<DeclarationNotFoundFailure>());
      final events =
          await auditLog.queryByEntity('Declaration', 'MISSING');
      expect(events.map((e) => e.action), containsAll([
        'declaration.status.transition-requested',
        'declaration.status.transition-failed',
      ]));
    });

    test(
      'applies a legal gateway transition, persists the new status, '
      'appends two audit events, and fires a notification',
      () async {
        repo.seed('DECL-1', _decl(DeclarationStatus.paymentPending));

        final result = await handler.handle(
          TransitionDeclarationStatusCommand(
            declarationId: 'DECL-1',
            tenantId: 'tenant-1',
            toStatus: DeclarationStatus.accepted,
            trigger: TransitionTrigger.gateway,
            actorId: 'atena-gateway',
            registrationNumber: 'CR-123',
            assessmentNumber: 4242,
          ),
        );

        expect(result.isOk, isTrue);
        expect(result.valueOrNull, DeclarationStatus.accepted);

        final stored = await repo.getById('DECL-1');
        expect(stored!.status, DeclarationStatus.accepted);
        expect(stored.customsRegistrationNumber, 'CR-123');
        expect(stored.assessmentNumber, 4242);

        final events =
            await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action).toList(), [
          'declaration.status.transition-requested',
          'declaration.status.transitioned',
        ]);
        final transitioned = events.last;
        expect(transitioned.payload['fromStatus'], 'PAYMENT_PENDING');
        expect(transitioned.payload['toStatus'], 'ACCEPTED');
        expect(transitioned.payload['trigger'], 'gateway');
        expect(transitioned.payload['registrationNumber'], 'CR-123');
        expect(transitioned.payload['assessmentNumber'], 4242);

        expect(dispatcher.fired, hasLength(1));
        final event = dispatcher.fired.single;
        expect(event.type,
            NotificationEventType.declarationStatusChanged);
        expect(event.previousStatus, DeclarationStatus.paymentPending);
        expect(event.newStatus, DeclarationStatus.accepted);
        expect(event.severity, NotificationSeverity.success);
        expect(event.metadata['registrationNumber'], 'CR-123');
      },
    );

    test(
      'returns IllegalTransitionFailure and audits `denied` for a '
      'transition that is not in the table',
      () async {
        repo.seed('DECL-2', _decl(DeclarationStatus.draft));
        final result = await handler.handle(
          TransitionDeclarationStatusCommand(
            declarationId: 'DECL-2',
            tenantId: 'tenant-1',
            toStatus: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.system,
            actorId: 'scheduler',
          ),
        );
        expect(result.isErr, isTrue);
        final failure =
            (result as Err<DeclarationStatus>).failure as IllegalTransitionFailure;
        expect(failure.reason, TransitionDenialReason.illegalTransition);
        expect(failure.attemptedFrom, DeclarationStatus.draft);
        expect(failure.attemptedTo, DeclarationStatus.confirmed);

        // State must NOT be persisted on illegal transitions.
        final stored = await repo.getById('DECL-2');
        expect(stored!.status, DeclarationStatus.draft);

        final events =
            await auditLog.queryByEntity('Declaration', 'DECL-2');
        expect(events.map((e) => e.action).toList(), [
          'declaration.status.transition-requested',
          'declaration.status.transition-denied',
        ]);
        // And no notification must be fired for a denied transition.
        expect(dispatcher.fired, isEmpty);
      },
    );

    test(
      'returns IllegalTransitionFailure for a user trigger against a '
      'gateway-only transition',
      () async {
        repo.seed('DECL-3', _decl(DeclarationStatus.validating));
        final result = await handler.handle(
          TransitionDeclarationStatusCommand(
            declarationId: 'DECL-3',
            tenantId: 'tenant-1',
            toStatus: DeclarationStatus.paymentPending,
            trigger: TransitionTrigger.user,
            actorId: 'user-42',
          ),
        );
        expect(result.isErr, isTrue);
        expect(
          ((result as Err<DeclarationStatus>).failure as IllegalTransitionFailure)
              .reason,
          TransitionDenialReason.triggerNotAllowed,
        );
      },
    );

    test(
      'transitions with firesNotification=false skip the dispatcher call',
      () async {
        repo.seed('DECL-4', _decl(DeclarationStatus.draft));
        final result = await handler.handle(
          TransitionDeclarationStatusCommand(
            declarationId: 'DECL-4',
            tenantId: 'tenant-1',
            toStatus: DeclarationStatus.registered,
            trigger: TransitionTrigger.system,
            actorId: 'scheduler',
          ),
        );
        expect(result.isOk, isTrue);
        expect(dispatcher.fired, isEmpty);
        final events =
            await auditLog.queryByEntity('Declaration', 'DECL-4');
        expect(events.last.action, 'declaration.status.transitioned');
      },
    );

    test(
      'concurrent writer surfaces ConcurrentTransitionFailure and '
      'writes a `conflict` audit event',
      () async {
        repo.seed('DECL-5', _decl(DeclarationStatus.paymentPending));
        // Wrap the real repo with a "surprise" mutator that changes the
        // status under our feet BEFORE updateStatus runs.
        final trickyRepo = _RaceyRepository(repo, whenCalled: () async {
          await repo.updateStatus(
            declarationId: 'DECL-5',
            expectedPreviousStatus: DeclarationStatus.paymentPending,
            newStatus: DeclarationStatus.rejected,
          );
        });
        final racyHandler = TransitionDeclarationStatusHandler(
          repository: trickyRepo,
          auditLog: auditLog,
          notifications: dispatcher,
          clock: () => fixedNow,
          idGenerator: () => 'evt-${++nextId}',
        );

        final result = await racyHandler.handle(
          TransitionDeclarationStatusCommand(
            declarationId: 'DECL-5',
            tenantId: 'tenant-1',
            toStatus: DeclarationStatus.accepted,
            trigger: TransitionTrigger.gateway,
            actorId: 'atena-gateway',
          ),
        );
        expect(result.isErr, isTrue);
        final failure = (result as Err<DeclarationStatus>).failure
            as ConcurrentTransitionFailure;
        expect(failure.observedStatus, DeclarationStatus.rejected);
        expect(failure.attemptedFrom, DeclarationStatus.paymentPending);

        final events =
            await auditLog.queryByEntity('Declaration', 'DECL-5');
        expect(events.last.action,
            'declaration.status.transition-conflict');
        expect(dispatcher.fired, isEmpty);
      },
    );

    test(
      'dispatcher infrastructure failure propagates as an exception '
      '(NOT a Result.err) — business transition already happened',
      () async {
        repo.seed('DECL-6', _decl(DeclarationStatus.paymentPending));
        dispatcher.arrangeNextFireThrows(StateError('dispatcher down'));

        await expectLater(
          handler.handle(
            TransitionDeclarationStatusCommand(
              declarationId: 'DECL-6',
              tenantId: 'tenant-1',
              toStatus: DeclarationStatus.accepted,
              trigger: TransitionTrigger.gateway,
              actorId: 'atena-gateway',
            ),
          ),
          throwsStateError,
        );
        // The transition+audit happen BEFORE the notification, so the
        // repository has the new status even though the notification
        // fan-out exploded.
        final stored = await repo.getById('DECL-6');
        expect(stored!.status, DeclarationStatus.accepted);
      },
    );
  });
}

Declaration _decl(DeclarationStatus status) {
  return Declaration(
    typeOfDeclaration: 'EX',
    generalProcedureCode: '1',
    officeOfDispatchExportCode: '001',
    officeOfEntryCode: '002',
    exporterCode: '310100580824',
    declarantCode: '310100975830',
    natureOfTransactionCode1: '1',
    natureOfTransactionCode2: '1',
    documentsReceived: true,
    shipping: const Shipping(countryOfExportCode: 'CR'),
    sadValuation: const SadValuation(),
    items: const [
      DeclarationItem(
        rank: 1,
        commercialDescription: 'LED grow lights 600W',
        procedure: ItemProcedure(
          itemCountryOfOriginCode: 'CR',
          extendedProcedureCode: '1000',
        ),
        itemValuation: ItemValuation(),
      ),
    ],
    status: status,
  );
}

/// A repository wrapper that fires [whenCalled] right before delegating
/// to the inner repository's `updateStatus`, simulating a concurrent
/// writer that races us to the store.
class _RaceyRepository implements DeclarationRepositoryPort {
  final DeclarationRepositoryPort inner;
  final Future<void> Function() whenCalled;
  bool _tripped = false;

  _RaceyRepository(this.inner, {required this.whenCalled});

  @override
  Future<Declaration?> getById(String declarationId) =>
      inner.getById(declarationId);

  @override
  Future<List<Declaration>> list(DeclarationListFilter filter) =>
      inner.list(filter);

  @override
  Future<void> updateStatus({
    required String declarationId,
    required DeclarationStatus expectedPreviousStatus,
    required DeclarationStatus newStatus,
    String? registrationNumber,
    String? assessmentSerial,
    int? assessmentNumber,
    String? assessmentDate,
  }) async {
    if (!_tripped) {
      _tripped = true;
      await whenCalled();
    }
    return inner.updateStatus(
      declarationId: declarationId,
      expectedPreviousStatus: expectedPreviousStatus,
      newStatus: newStatus,
      registrationNumber: registrationNumber,
      assessmentSerial: assessmentSerial,
      assessmentNumber: assessmentNumber,
      assessmentDate: assessmentDate,
    );
  }
}
