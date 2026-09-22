import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/notification_type.dart';
import 'package:servio/features/notifications/data/models/notification_model.dart';
import 'package:servio/features/notifications/domain/notification_factory.dart';

void main() {
  test('round-trips a notification', () {
    final notification = NotificationModel(
      notificationId: 'notif-1',
      recipientId: 'student-1',
      recipientRole: 'student',
      senderId: 'coordinator-1',
      senderName: 'Grace Okon',
      title: 'Placement Approved',
      message: 'Your placement at MTN Nigeria has been approved.',
      type: NotificationType.placement,
      relatedEntityId: 'int-1',
      relatedEntityType: 'internship',
      isRead: false,
      createdAt: DateTime.utc(2026, 9, 3, 10),
    );

    final json = notification.toJson();
    expect(json['type'], 'placement');
    expect(json['isRead'], isFalse);

    final roundTripped = NotificationModel.fromJson(json);
    expect(roundTripped.notificationId, 'notif-1');
    expect(roundTripped.type, NotificationType.placement);
    expect(roundTripped.relatedEntityId, 'int-1');
  });

  test('marking read is the only mutation copyWith allows', () {
    final notification = NotificationModel(
      notificationId: 'notif-1',
      recipientId: 'student-1',
      recipientRole: 'student',
      title: 'Placement Approved',
      message: 'Approved.',
      type: NotificationType.placement,
      isRead: false,
      createdAt: DateTime.utc(2026, 9, 3, 10),
    );

    final read = notification.copyWith(isRead: true);
    expect(read.isRead, isTrue);
    expect(read.title, notification.title);
    expect(read.createdAt, notification.createdAt);
  });

  test('an unrecognized type falls back to system rather than throwing', () {
    // A notification is a passive message — one written by a newer app
    // version shouldn't be able to break the whole list.
    expect(
      NotificationTypeSerialization.fromFirestore('something_new'),
      NotificationType.system,
    );
  });

  group('NotificationFactory', () {
    test('addresses placement approval to the student', () {
      final notification = NotificationFactory.placementApproved(
        notificationId: 'notif-1',
        studentId: 'student-1',
        internshipId: 'int-1',
        companyName: 'MTN Nigeria',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        createdAt: DateTime.utc(2026, 9, 3),
      );

      expect(notification.recipientId, 'student-1');
      expect(notification.recipientRole, 'student');
      expect(notification.senderName, 'Grace Okon');
      expect(notification.type, NotificationType.placement);
      expect(notification.relatedEntityType, 'internship');
      expect(notification.message, contains('MTN Nigeria'));
      expect(notification.isRead, isFalse);
    });

    test('addresses the assignment notice to the lecturer, not the student', () {
      final notification = NotificationFactory.studentAssignedToLecturer(
        notificationId: 'notif-2',
        lecturerId: 'lecturer-1',
        internshipId: 'int-1',
        studentName: 'Amaka Nwosu',
        companyName: 'MTN Nigeria',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        createdAt: DateTime.utc(2026, 9, 3),
      );

      expect(notification.recipientId, 'lecturer-1');
      expect(notification.recipientRole, 'lecturer');
      expect(notification.message, contains('Amaka Nwosu'));
    });

    test('completion notifies the student', () {
      final notification = NotificationFactory.internshipCompleted(
        notificationId: 'notif-4',
        studentId: 'student-1',
        internshipId: 'int-1',
        companyName: 'Andela Nigeria',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        createdAt: DateTime.utc(2026, 9, 14),
      );
      expect(notification.recipientId, 'student-1');
      expect(notification.title, 'Internship Completed');
      expect(notification.message, contains('Andela Nigeria'));
    });

    test('account approval notifies the lecturer, not the coordinator', () {
      final notification = NotificationFactory.lecturerAccountApproved(
        notificationId: 'notif-5',
        lecturerId: 'lecturer-1',
        coordinatorId: 'coordinator-1',
        coordinatorName: 'Grace Okon',
        createdAt: DateTime.utc(2026, 9, 14),
      );
      expect(notification.recipientId, 'lecturer-1');
      expect(notification.recipientRole, 'lecturer');
      expect(notification.type, NotificationType.system);
    });

    test('supervision reports notify the student who was visited', () {
      final notification = NotificationFactory.supervisionReportSubmitted(
        notificationId: 'notif-3',
        studentId: 'student-1',
        reportId: 'sup-1',
        lecturerId: 'lecturer-1',
        lecturerName: 'Dr. Samuel Johnson',
        visitDate: DateTime.utc(2026, 9, 2),
        createdAt: DateTime.utc(2026, 9, 3),
      );

      expect(notification.recipientId, 'student-1');
      expect(notification.type, NotificationType.supervision);
      expect(notification.relatedEntityType, 'supervision_report');
      expect(notification.message, contains('2026-09-02'));
    });
  });
}
