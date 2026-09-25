import '../data/models/audit_event_model.dart';

/// Builds the audit events Servio records for each significant action
/// (FR-AUDIT-001).
///
/// Kept in one place for the same reason as `NotificationFactory`: the
/// wording, action names, and entity types of every audit record are
/// visible together instead of being spread across the repositories that
/// write them. Callers supply a fresh document ID and timestamp; the
/// resulting event is written inside the same batch or transaction as the
/// action it describes, so the trail can never claim something that
/// didn't commit.
///
/// The `description` doubles as the human-readable activity-log line —
/// the SRS notes the audit trail and the activity log are "generated from
/// the same underlying events but serve different audiences", so Servio
/// records the event once and renders it two ways.
abstract final class AuditEventFactory {
  /// Student submitted a placement for review.
  static AuditEventModel placementSubmitted({
    required String eventId,
    required String studentId,
    required String studentName,
    required String internshipId,
    required String companyName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: studentId,
      actorName: studentName,
      actorRole: 'student',
      action: 'submitted_placement',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: 'Submitted a placement at $companyName for review.',
      createdAt: createdAt,
    );
  }

  /// Coordinator approved a placement.
  static AuditEventModel placementApproved({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String internshipId,
    required String studentId,
    required String studentName,
    required String companyName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: 'approved_placement',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: "Approved $studentName's placement at $companyName.",
      metadata: const {
        'previousStatus': 'pending_review',
        'newStatus': 'approved',
      },
      createdAt: createdAt,
    );
  }

  /// Coordinator rejected a placement.
  static AuditEventModel placementRejected({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String internshipId,
    required String studentId,
    required String studentName,
    required String companyName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: 'rejected_placement',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: "Rejected $studentName's placement at $companyName.",
      metadata: const {
        'previousStatus': 'pending_review',
        'newStatus': 'rejected',
      },
      createdAt: createdAt,
    );
  }

  /// Coordinator assigned a supervising lecturer.
  static AuditEventModel lecturerAssigned({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String internshipId,
    required String studentId,
    required String studentName,
    required String lecturerName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: 'assigned_lecturer',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: 'Assigned $lecturerName to supervise $studentName.',
      metadata: const {'previousStatus': 'approved', 'newStatus': 'assigned'},
      createdAt: createdAt,
    );
  }

  /// Coordinator activated an internship, starting the placement.
  static AuditEventModel internshipActivated({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String internshipId,
    required String studentId,
    required String studentName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: 'activated_internship',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: "Started $studentName's internship.",
      metadata: const {'previousStatus': 'assigned', 'newStatus': 'active'},
      createdAt: createdAt,
    );
  }

  /// Coordinator marked an internship completed ("Internship Completed" in
  /// the SRS's required-event list).
  static AuditEventModel internshipCompleted({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String internshipId,
    required String studentId,
    required String studentName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: 'completed_internship',
      entityType: 'internship',
      entityId: internshipId,
      targetUserId: studentId,
      description: "Marked $studentName's internship as completed.",
      metadata: const {'previousStatus': 'active', 'newStatus': 'completed'},
      createdAt: createdAt,
    );
  }

  /// A user created their own account ("Student Created" in the SRS's
  /// required-event list; lecturers self-register the same way).
  static AuditEventModel accountCreated({
    required String eventId,
    required String userId,
    required String userName,
    required String role,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: userId,
      actorName: userName,
      actorRole: role,
      action: 'created_account',
      entityType: 'user',
      entityId: userId,
      targetUserId: userId,
      description: role == 'lecturer'
          ? 'Registered as a lecturer (awaiting coordinator approval).'
          : 'Registered as a student.',
      createdAt: createdAt,
    );
  }

  /// A user deleted their own account. Their placement records stay (they
  /// belong to the institution), so the trail records who left and when.
  static AuditEventModel accountDeleted({
    required String eventId,
    required String userId,
    required String userName,
    required String role,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: userId,
      actorName: userName,
      actorRole: role,
      action: 'deleted_account',
      entityType: 'user',
      entityId: userId,
      targetUserId: userId,
      description: 'Deleted their Servio account.',
      createdAt: createdAt,
    );
  }

  /// Coordinator approved or deactivated a lecturer account.
  static AuditEventModel lecturerAccessChanged({
    required String eventId,
    required String coordinatorId,
    required String coordinatorName,
    required String lecturerId,
    required String lecturerName,
    required bool isActive,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: coordinatorId,
      actorName: coordinatorName,
      actorRole: 'coordinator',
      action: isActive ? 'activated_lecturer' : 'deactivated_lecturer',
      entityType: 'user',
      entityId: lecturerId,
      targetUserId: lecturerId,
      description: isActive
          ? "Approved $lecturerName's lecturer account."
          : "Deactivated $lecturerName's lecturer account.",
      metadata: {'previousIsActive': !isActive, 'newIsActive': isActive},
      createdAt: createdAt,
    );
  }

  /// Student checked in for the day.
  static AuditEventModel attendanceCheckedIn({
    required String eventId,
    required String studentId,
    required String studentName,
    required String attendanceId,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: studentId,
      actorName: studentName,
      actorRole: 'student',
      action: 'checked_in',
      entityType: 'attendance',
      entityId: attendanceId,
      targetUserId: studentId,
      description: 'Checked in.',
      createdAt: createdAt,
    );
  }

  /// Student checked out for the day.
  static AuditEventModel attendanceCheckedOut({
    required String eventId,
    required String studentId,
    required String studentName,
    required String attendanceId,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: studentId,
      actorName: studentName,
      actorRole: 'student',
      action: 'checked_out',
      entityType: 'attendance',
      entityId: attendanceId,
      targetUserId: studentId,
      description: 'Checked out.',
      createdAt: createdAt,
    );
  }

  /// Student saved a logbook entry — created for the first time, or
  /// edited while still editable (BR-LOG-004).
  static AuditEventModel logbookSaved({
    required String eventId,
    required String studentId,
    required String studentName,
    required String entryId,
    required DateTime entryDate,
    required bool isFirstSave,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: studentId,
      actorName: studentName,
      actorRole: 'student',
      action: isFirstSave ? 'created_logbook_entry' : 'edited_logbook_entry',
      entityType: 'logbook_entry',
      entityId: entryId,
      targetUserId: studentId,
      description: isFirstSave
          ? 'Submitted a logbook entry for ${_formatDate(entryDate)}.'
          : 'Edited the logbook entry for ${_formatDate(entryDate)}.',
      createdAt: createdAt,
    );
  }

  /// Lecturer approved a logbook entry.
  static AuditEventModel logbookApproved({
    required String eventId,
    required String lecturerId,
    required String lecturerName,
    required String entryId,
    required String studentId,
    required String studentName,
    required DateTime entryDate,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: lecturerId,
      actorName: lecturerName,
      actorRole: 'lecturer',
      action: 'approved_logbook_entry',
      entityType: 'logbook_entry',
      entityId: entryId,
      targetUserId: studentId,
      description:
          "Approved $studentName's logbook entry for "
          '${_formatDate(entryDate)}.',
      metadata: const {'previousStatus': 'pending', 'newStatus': 'approved'},
      createdAt: createdAt,
    );
  }

  /// Lecturer requested changes on a logbook entry.
  static AuditEventModel logbookChangesRequested({
    required String eventId,
    required String lecturerId,
    required String lecturerName,
    required String entryId,
    required String studentId,
    required String studentName,
    required DateTime entryDate,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: lecturerId,
      actorName: lecturerName,
      actorRole: 'lecturer',
      action: 'requested_logbook_changes',
      entityType: 'logbook_entry',
      entityId: entryId,
      targetUserId: studentId,
      description:
          "Requested changes on $studentName's logbook entry for "
          '${_formatDate(entryDate)}.',
      metadata: const {
        'previousStatus': 'pending',
        'newStatus': 'changes_requested',
      },
      createdAt: createdAt,
    );
  }

  /// Lecturer recorded a supervision visit (FR-SUP-006).
  static AuditEventModel supervisionReportCreated({
    required String eventId,
    required String lecturerId,
    required String lecturerName,
    required String reportId,
    required String studentId,
    required String studentName,
    required DateTime createdAt,
  }) {
    return AuditEventModel(
      eventId: eventId,
      actorId: lecturerId,
      actorName: lecturerName,
      actorRole: 'lecturer',
      action: 'created_supervision_report',
      entityType: 'supervision_report',
      entityId: reportId,
      targetUserId: studentId,
      description: 'Submitted a supervision visit report for $studentName.',
      createdAt: createdAt,
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
