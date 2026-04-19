/// Tests for [DeclarationStateMachine] — the transition policy.
///
/// We exercise:
///   * every encoded transition is legal for at least one trigger;
///   * a representative set of illegal transitions is rejected;
///   * role-gated transitions honor the role hierarchy;
///   * the severity of side-effect flags (fires, audits) matches policy.
///
/// We explicitly avoid golden-matching the entire table — the intent is
/// to catch regressions on the CONTRACT, not lock the table in stone.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('DeclarationStateMachine (default table)', () {
    const sm = DeclarationStateMachine();

    test('exposes at least 25 transitions (SRD floor for DGA coverage)', () {
      expect(sm.transitions.length, greaterThanOrEqualTo(25));
    });

    test(
      'multi-entry (from, to) pairs must differ in trigger policy '
      '(otherwise the duplicate entry is unreachable)',
      () {
        final byPair = <String, List<StateTransition>>{};
        for (final t in sm.transitions) {
          byPair.putIfAbsent('${t.from.code}->${t.to.code}', () => []).add(t);
        }
        for (final entry in byPair.entries) {
          if (entry.value.length <= 1) continue;
          // When the same (from, to) appears more than once, at least one
          // of `allowedTriggers` or `requiresActorRole` must differ between
          // the entries — otherwise `canTransition` would never reach the
          // second entry and it would be dead code.
          final triggerSets =
              entry.value.map((t) => t.allowedTriggers.toList()..sort((a, b) => a.name.compareTo(b.name))).toList();
          final roleList =
              entry.value.map((t) => t.requiresActorRole?.code ?? '').toList();
          final sigs = {
            for (var i = 0; i < entry.value.length; i++)
              '${triggerSets[i].map((t) => t.name).join(",")}|${roleList[i]}'
          };
          expect(sigs.length, entry.value.length,
              reason: 'unreachable duplicate transition for ${entry.key}: '
                  'multiple entries share the same trigger policy');
        }
      },
    );

    test('no transition has from == to', () {
      for (final t in sm.transitions) {
        expect(t.from, isNot(t.to),
            reason: 'no-op transitions are not allowed');
      }
    });

    test('every transition has at least one allowed trigger', () {
      for (final t in sm.transitions) {
        expect(t.allowedTriggers, isNotEmpty,
            reason: 'transition ${t.from.code}->${t.to.code} has no triggers');
      }
    });

    group('canTransition', () {
      test('registered -> validating is allowed via gateway', () {
        final check = sm.canTransition(
          from: DeclarationStatus.registered,
          to: DeclarationStatus.validating,
          trigger: TransitionTrigger.gateway,
        );
        expect(check, isA<TransitionAllowed>());
      });

      test('paymentPending -> accepted fires a notification', () {
        final check = sm.canTransition(
          from: DeclarationStatus.paymentPending,
          to: DeclarationStatus.accepted,
          trigger: TransitionTrigger.gateway,
        );
        expect(check, isA<TransitionAllowed>());
        final transition = (check as TransitionAllowed).transition;
        expect(transition.firesNotification, isTrue);
      });

      test('levante -> levanteTransit does NOT fire a notification', () {
        final check = sm.canTransition(
          from: DeclarationStatus.levante,
          to: DeclarationStatus.levanteTransit,
          trigger: TransitionTrigger.gateway,
        );
        expect(check, isA<TransitionAllowed>());
        expect((check as TransitionAllowed).transition.firesNotification,
            isFalse);
      });

      test('same-state transition is rejected as illegal', () {
        final check = sm.canTransition(
          from: DeclarationStatus.registered,
          to: DeclarationStatus.registered,
          trigger: TransitionTrigger.system,
        );
        expect(check, isA<TransitionDenied>());
        expect((check as TransitionDenied).reason,
            TransitionDenialReason.illegalTransition);
      });

      test('draft -> confirmed is rejected as illegal', () {
        final check = sm.canTransition(
          from: DeclarationStatus.draft,
          to: DeclarationStatus.confirmed,
          trigger: TransitionTrigger.system,
        );
        expect(check, isA<TransitionDenied>());
        expect((check as TransitionDenied).reason,
            TransitionDenialReason.illegalTransition);
      });

      test('confirmed -> draft (backwards) is rejected as illegal', () {
        final check = sm.canTransition(
          from: DeclarationStatus.confirmed,
          to: DeclarationStatus.draft,
          trigger: TransitionTrigger.user,
          actorRole: Role.admin,
        );
        expect(check, isA<TransitionDenied>());
        expect((check as TransitionDenied).reason,
            TransitionDenialReason.illegalTransition);
      });

      test(
        'gateway-only transition is rejected when triggered by user',
        () {
          final check = sm.canTransition(
            from: DeclarationStatus.validating,
            to: DeclarationStatus.paymentPending,
            trigger: TransitionTrigger.user,
            actorRole: Role.admin,
          );
          expect(check, isA<TransitionDenied>());
          expect((check as TransitionDenied).reason,
              TransitionDenialReason.triggerNotAllowed);
        },
      );

      test('draft -> cancelled requires at least agent role', () {
        final denied = sm.canTransition(
          from: DeclarationStatus.draft,
          to: DeclarationStatus.cancelled,
          trigger: TransitionTrigger.user,
          actorRole: Role.importer,
        );
        expect(denied, isA<TransitionDenied>());
        expect((denied as TransitionDenied).reason,
            TransitionDenialReason.insufficientRole);

        final allowed = sm.canTransition(
          from: DeclarationStatus.draft,
          to: DeclarationStatus.cancelled,
          trigger: TransitionTrigger.user,
          actorRole: Role.agent,
        );
        expect(allowed, isA<TransitionAllowed>());
      });

      test(
        'confirmationWindow -> confirmed manual path requires supervisor',
        () {
          // Gateway path: no role requirement.
          final gateway = sm.canTransition(
            from: DeclarationStatus.confirmationWindow,
            to: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.gateway,
          );
          expect(gateway, isA<TransitionAllowed>());

          // User path with agent role: denied (supervisor+ required).
          final agentCheck = sm.canTransition(
            from: DeclarationStatus.confirmationWindow,
            to: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.user,
            actorRole: Role.agent,
          );
          expect(agentCheck, isA<TransitionDenied>());
          expect((agentCheck as TransitionDenied).reason,
              TransitionDenialReason.insufficientRole);

          // User path with supervisor role: allowed.
          final supCheck = sm.canTransition(
            from: DeclarationStatus.confirmationWindow,
            to: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.user,
            actorRole: Role.supervisor,
          );
          expect(supCheck, isA<TransitionAllowed>());

          // User path with admin role: allowed (admin outranks supervisor).
          final adminCheck = sm.canTransition(
            from: DeclarationStatus.confirmationWindow,
            to: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.user,
            actorRole: Role.admin,
          );
          expect(adminCheck, isA<TransitionAllowed>());
        },
      );

      test('user-triggered gateway transition with no role returns denial',
          () {
        final check = sm.canTransition(
          from: DeclarationStatus.validating,
          to: DeclarationStatus.paymentPending,
          trigger: TransitionTrigger.user,
          // no actorRole — still denied because the transition only
          // accepts gateway/system triggers, not user.
        );
        expect(check, isA<TransitionDenied>());
      });
    });

    group('apply', () {
      test('returns a StateTransitionResult for a legal transition', () {
        final result = sm.apply(
          from: DeclarationStatus.registered,
          to: DeclarationStatus.validating,
          trigger: TransitionTrigger.gateway,
        );
        expect(result.previousStatus, DeclarationStatus.registered);
        expect(result.newStatus, DeclarationStatus.validating);
        expect(result.shouldAudit, isTrue);
      });

      test('throws StateError for an illegal transition', () {
        expect(
          () => sm.apply(
            from: DeclarationStatus.draft,
            to: DeclarationStatus.confirmed,
            trigger: TransitionTrigger.system,
          ),
          throwsStateError,
        );
      });
    });

    group('outgoingFrom', () {
      test('returns every transition leaving draft', () {
        final outs = sm.outgoingFrom(DeclarationStatus.draft);
        expect(outs.map((t) => t.to), containsAll([
          DeclarationStatus.registered,
          DeclarationStatus.cancelled,
        ]));
      });

      test('returns empty for a state with no outgoing transitions', () {
        // `finalConfirmed` is an accepted terminal state in the default
        // table — no further transitions are registered from it.
        final outs = sm.outgoingFrom(DeclarationStatus.finalConfirmed);
        expect(outs, isEmpty);
      });
    });

    group('notification policy alignment', () {
      // The `triggersNotification` getter on DeclarationStatus is a
      // rough "does the arrival at this status typically matter to a
      // user?" hint. Every state flagged by it SHOULD have at least one
      // incoming transition that fires a notification (otherwise the
      // hint is unreachable).
      test('every status with triggersNotification has at least one '
          'firesNotification transition into it', () {
        for (final status in DeclarationStatus.values) {
          if (!status.triggersNotification) continue;
          final incoming = sm.transitions.where((t) => t.to == status);
          final hasFiring = incoming.any((t) => t.firesNotification);
          expect(hasFiring, isTrue,
              reason: 'status ${status.code} is flagged '
                  'triggersNotification but no transition into it fires');
        }
      });
    });

    group('custom transition table', () {
      test('apply works with a test-only transition list', () {
        const customSm = DeclarationStateMachine(
          transitions: [
            StateTransition(
              from: DeclarationStatus.draft,
              to: DeclarationStatus.finalConfirmed,
              trigger: 'test.warp-drive',
              allowedTriggers: {TransitionTrigger.system},
              dgaActivity: 'test',
            ),
          ],
        );
        final result = customSm.apply(
          from: DeclarationStatus.draft,
          to: DeclarationStatus.finalConfirmed,
          trigger: TransitionTrigger.system,
        );
        expect(result.newStatus, DeclarationStatus.finalConfirmed);
      });
    });
  });
}
