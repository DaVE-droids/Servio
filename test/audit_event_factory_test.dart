import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/audit/data/models/audit_event_model.dart';
import 'package:servio/features/audit/domain/audit_event_factory.dart';
import 'package:servio/features/audit/presentation/controllers/audit_state.dart';

AuditEventModel _event({
  String eventId = 'e1',
  String actorId = 'actor-1',
  String actorName = 'Grace Okon',
  String actorRole = 'coordinator',
  String action = 'approved_placement',
  String entityType = 'internship',
  String entityId = 'int-1',
  DateTime? createdAt,
}) {
  return AuditEventModel(
    eventId: eventId,
    actorId: actorId,
    actorName: actorName,
    actorRole: actorRole,
    action: action,
    entityType: entityType,
    entityId: entityId,
    description: 'Something happened.',
    createdAt: createdAt ?? DateTime.utc(2026, 9, 5, 9),
  );
}

void main() {
  group('AuditEventFactory', () {
    test('records the coordinator as the actor and the student as target', () {
      final event = AuditEventFactory.placementApproved(
        eventId: 'e1',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        internshipId: 'int-1',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        companyName: 'MTN Nigeria',
        createdAt: DateTime.utc(2026, 9, 5),
      );

      expect(event.actorId, 'coordinator-1');
      expect(event.actorRole, 'coordinator');
      expect(event.targetUserId, 'student-1');
      expect(event.action, 'approved_placement');
      expect(event.entityType, 'internship');
      expect(event.entityId, 'int-1');
      expect(event.description, contains('Amaka Nwosu'));
      expect(event.description, contains('MTN Nigeria'));
    });

    test('records the student as their own actor when they submit', () {
      final event = AuditEventFactory.placementSubmitted(
        eventId: 'e1',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        internshipId: 'int-1',
        companyName: 'MTN Nigeria',
        createdAt: DateTime.utc(2026, 9, 5),
      );

      // BR-AUDIT-003: exactly one actor, and here it's the student
      // themselves — not the coordinator who will later review it.
      expect(event.actorId, 'student-1');
      expect(event.actorRole, 'student');
    });

    test('distinguishes a first logbook save from a later edit', () {
      final created = AuditEventFactory.logbookSaved(
        eventId: 'e1',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        entryId: 'entry-1',
        entryDate: DateTime.utc(2026, 9, 4),
        isFirstSave: true,
        createdAt: DateTime.utc(2026, 9, 4),
      );
      final edited = AuditEventFactory.logbookSaved(
        eventId: 'e2',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        entryId: 'entry-1',
        entryDate: DateTime.utc(2026, 9, 4),
        isFirstSave: false,
        createdAt: DateTime.utc(2026, 9, 4, 18),
      );

      expect(created.action, 'created_logbook_entry');
      expect(edited.action, 'edited_logbook_entry');
      expect(edited.entityId, created.entityId);
    });

    test('captures the status change as previous/new metadata', () {
      final event = AuditEventFactory.lecturerAssigned(
        eventId: 'e1',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        internshipId: 'int-1',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        lecturerName: 'Dr. Samuel Johnson',
        createdAt: DateTime.utc(2026, 9, 5),
      );

      // "What was the previous value?" is one of the five questions the
      // SRS says every audit record should answer.
      expect(event.metadata?['previousStatus'], 'approved');
      expect(event.metadata?['newStatus'], 'assigned');
    });

    test('round-trips through JSON', () {
      final event = AuditEventFactory.supervisionReportCreated(
        eventId: 'e1',
        lecturerId: 'lecturer-1',
        lecturerName: 'Dr. Samuel Johnson',
        reportId: 'sup-1',
        studentId: 'student-1',
        studentName: 'Amaka Nwosu',
        createdAt: DateTime.utc(2026, 9, 5, 11, 30),
      );

      final roundTripped = AuditEventModel.fromJson(event.toJson());
      expect(roundTripped.eventId, 'e1');
      expect(roundTripped.action, 'created_supervision_report');
      expect(roundTripped.entityId, 'sup-1');
      expect(roundTripped.createdAt, DateTime.utc(2026, 9, 5, 11, 30));
    });

    test('completion records the coordinator and the status change', () {
      final event = AuditEventFactory.internshipCompleted(
        eventId: 'e1',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        internshipId: 'int-1',
        studentId: 'student-1',
        studentName: 'Fatima Bello',
        createdAt: DateTime.utc(2026, 9, 14),
      );
      expect(event.action, 'completed_internship');
      expect(event.actorRole, 'coordinator');
      expect(event.metadata?['newStatus'], 'completed');
      expect(event.description, contains('Fatima Bello'));
    });

    test('a lecturer sign-up says it is awaiting approval', () {
      final event = AuditEventFactory.accountCreated(
        eventId: 'e1',
        userId: 'lecturer-1',
        userName: 'Adaeze Obi',
        role: 'lecturer',
        createdAt: DateTime.utc(2026, 9, 14),
      );
      expect(event.actorId, 'lecturer-1');
      expect(event.entityType, 'user');
      expect(event.description, contains('awaiting coordinator approval'));
    });

    test(
      'an account deletion is recorded as the user acting on themselves',
      () {
        final event = AuditEventFactory.accountDeleted(
          eventId: 'e1',
          userId: 'student-1',
          userName: 'Tunde Bakare',
          role: 'student',
          createdAt: DateTime.utc(2026, 9, 22),
        );
        // The security rules only accept an event whose actor is the signed-in
        // user, so the deleting user must be the actor.
        expect(event.actorId, 'student-1');
        expect(event.targetUserId, 'student-1');
        expect(event.action, 'deleted_account');
        expect(event.entityType, 'user');
      },
    );

    test('approving and deactivating a lecturer are distinct actions', () {
      AuditEventModel build(bool isActive) =>
          AuditEventFactory.lecturerAccessChanged(
            eventId: 'e1',
            coordinatorId: 'coordinator-1',
            coordinatorName: 'Grace Okon',
            lecturerId: 'lecturer-1',
            lecturerName: 'Adaeze Obi',
            isActive: isActive,
            createdAt: DateTime.utc(2026, 9, 14),
          );
      expect(build(true).action, 'activated_lecturer');
      expect(build(false).action, 'deactivated_lecturer');
      expect(build(false).metadata?['previousIsActive'], isTrue);
    });

    test('is immutable — copyWith returns the same event', () {
      // BR-AUDIT-001/FR-AUDIT-003: audit records cannot be edited.
      final event = _event();
      expect(identical(event.copyWith(), event), isTrue);
    });
  });

  group('AuditFilter', () {
    test('an empty filter matches everything and reads as inactive', () {
      const filter = AuditFilter();
      expect(filter.isActive, isFalse);
      expect(filter.matches(_event()), isTrue);
    });

    test('filters by actor, action, and entity type', () {
      final event = _event(actorId: 'actor-1', action: 'approved_placement');

      expect(const AuditFilter(actorId: 'actor-1').matches(event), isTrue);
      expect(const AuditFilter(actorId: 'actor-2').matches(event), isFalse);
      expect(
        const AuditFilter(action: 'approved_placement').matches(event),
        isTrue,
      );
      expect(
        const AuditFilter(action: 'rejected_placement').matches(event),
        isFalse,
      );
      expect(
        const AuditFilter(entityType: 'logbook_entry').matches(event),
        isFalse,
      );
    });

    test('date bounds are inclusive of the whole day', () {
      final event = _event(createdAt: DateTime.utc(2026, 9, 5, 9));
      final day = event.createdAt.toLocal();
      final sameDay = DateTime(day.year, day.month, day.day);

      // A range of exactly one day must still contain an event recorded
      // partway through it — the filter compares days, not instants.
      expect(AuditFilter(from: sameDay, to: sameDay).matches(event), isTrue);
      expect(
        AuditFilter(from: sameDay.add(const Duration(days: 1))).matches(event),
        isFalse,
      );
      expect(
        AuditFilter(
          to: sameDay.subtract(const Duration(days: 1)),
        ).matches(event),
        isFalse,
      );
    });

    test('clear flags unset a field instead of being ignored', () {
      const filter = AuditFilter(actorId: 'actor-1', action: 'checked_in');
      expect(filter.copyWith(clearActorId: true).actorId, isNull);
      expect(filter.copyWith(clearActorId: true).action, 'checked_in');
    });
  });

  group('AuditState', () {
    final events = [
      _event(eventId: 'e1', actorId: 'a1', actorName: 'Grace Okon'),
      _event(
        eventId: 'e2',
        actorId: 'a2',
        actorName: 'Dr. Samuel Johnson',
        actorRole: 'lecturer',
        action: 'approved_logbook_entry',
        entityType: 'logbook_entry',
      ),
    ];

    test('derives the filter options from the loaded events', () {
      final state = AuditState(events: events);
      expect(state.actors, {'a1': 'Grace Okon', 'a2': 'Dr. Samuel Johnson'});
      expect(state.actions, ['approved_logbook_entry', 'approved_placement']);
      expect(state.entityTypes, ['internship', 'logbook_entry']);
    });

    test('visibleEvents applies the filter without dropping the source', () {
      final state = AuditState(
        events: events,
        filter: const AuditFilter(entityType: 'logbook_entry'),
      );
      expect(state.visibleEvents.length, 1);
      expect(state.visibleEvents.single.eventId, 'e2');
      expect(state.events.length, 2);
    });

    test('a new message survives clearMessages in the same copyWith', () {
      // The precedence bug that silently disabled every snackbar once
      // before — asserted here so it can't come back in this state class.
      const state = AuditState(errorMessage: 'old');
      final updated = state.copyWith(clearMessages: true, errorMessage: 'new');
      expect(updated.errorMessage, 'new');
      expect(state.copyWith(clearMessages: true).errorMessage, isNull);
    });
  });
}
