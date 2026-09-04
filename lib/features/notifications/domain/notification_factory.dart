import '../../../core/enums/notification_type.dart';
import '../data/models/notification_model.dart';

/// Builds the notifications Servio sends for each business event.
///
/// Kept in one place so the wording and categorisation of every
/// notification is visible together, rather than spread across the
/// repositories that write them. Callers supply a fresh document ID and
/// timestamp; the resulting model is written inside the same batch as the
/// action it describes, so a notification can never exist for an action
/// that didn't commit.
abstract final class NotificationFactory {
  /// Placement approved by a coordinator.
  static NotificationModel placementApproved({
    required String notificationId,
    required String studentId,
    required String internshipId,
    required String companyName,
    required String coordinatorId,
    required String coordinatorName,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: coordinatorId,
      senderName: coordinatorName,
      title: 'Placement Approved',
      message:
          'Your placement at $companyName has been approved. A lecturer will '
          'be assigned to supervise you.',
      type: NotificationType.placement,
      relatedEntityId: internshipId,
      relatedEntityType: 'internship',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// Placement rejected by a coordinator.
  static NotificationModel placementRejected({
    required String notificationId,
    required String studentId,
    required String internshipId,
    required String companyName,
    required String coordinatorId,
    required String coordinatorName,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: coordinatorId,
      senderName: coordinatorName,
      title: 'Placement Rejected',
      message:
          'Your placement at $companyName was not approved. Please contact '
          'your coordinator for details.',
      type: NotificationType.placement,
      relatedEntityId: internshipId,
      relatedEntityType: 'internship',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// Tells the student which lecturer will supervise them.
  static NotificationModel lecturerAssignedToStudent({
    required String notificationId,
    required String studentId,
    required String internshipId,
    required String lecturerName,
    required String coordinatorId,
    required String coordinatorName,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: coordinatorId,
      senderName: coordinatorName,
      title: 'Lecturer Assigned',
      message: '$lecturerName has been assigned to supervise your placement.',
      type: NotificationType.placement,
      relatedEntityId: internshipId,
      relatedEntityType: 'internship',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// Tells the lecturer they have a new student to supervise.
  static NotificationModel studentAssignedToLecturer({
    required String notificationId,
    required String lecturerId,
    required String internshipId,
    required String studentName,
    required String companyName,
    required String coordinatorId,
    required String coordinatorName,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: lecturerId,
      recipientRole: 'lecturer',
      senderId: coordinatorId,
      senderName: coordinatorName,
      title: 'New Student Assigned',
      message:
          'You have been assigned to supervise $studentName at $companyName.',
      type: NotificationType.placement,
      relatedEntityId: internshipId,
      relatedEntityType: 'internship',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// Logbook entry approved by the assigned lecturer.
  static NotificationModel logbookApproved({
    required String notificationId,
    required String studentId,
    required String entryId,
    required String lecturerId,
    required String lecturerName,
    required DateTime entryDate,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: lecturerId,
      senderName: lecturerName,
      title: 'Logbook Entry Approved',
      message:
          '$lecturerName approved your logbook entry for '
          '${_formatDate(entryDate)}.',
      type: NotificationType.logbook,
      relatedEntityId: entryId,
      relatedEntityType: 'logbook_entry',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// Lecturer requested changes to a logbook entry.
  static NotificationModel logbookChangesRequested({
    required String notificationId,
    required String studentId,
    required String entryId,
    required String lecturerId,
    required String lecturerName,
    required DateTime entryDate,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: lecturerId,
      senderName: lecturerName,
      title: 'Logbook Changes Requested',
      message:
          '$lecturerName requested changes to your logbook entry for '
          '${_formatDate(entryDate)}.',
      type: NotificationType.logbook,
      relatedEntityId: entryId,
      relatedEntityType: 'logbook_entry',
      isRead: false,
      createdAt: createdAt,
    );
  }

  /// A supervision visit report was filed for this student.
  static NotificationModel supervisionReportSubmitted({
    required String notificationId,
    required String studentId,
    required String reportId,
    required String lecturerId,
    required String lecturerName,
    required DateTime visitDate,
    required DateTime createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: studentId,
      recipientRole: 'student',
      senderId: lecturerId,
      senderName: lecturerName,
      title: 'Supervision Visit Recorded',
      message:
          '$lecturerName recorded a supervision visit on '
          '${_formatDate(visitDate)}.',
      type: NotificationType.supervision,
      relatedEntityId: reportId,
      relatedEntityType: 'supervision_report',
      isRead: false,
      createdAt: createdAt,
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
