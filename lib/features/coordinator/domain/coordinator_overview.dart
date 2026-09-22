import '../../../core/enums/internship_status.dart';
import '../../internship/data/models/internship_model.dart';
import '../../profile/data/models/user_model.dart';
import '../../reports/data/models/internship_progress.dart';

/// Everything a coordinator's Students, Lecturers, and Reports screens
/// show, loaded once and shared.
///
/// Deliberately plain Dart with no Firebase inside, so the grouping rules
/// below (which placement counts as a student's "current" one, what a
/// lecturer's workload is) can be unit-tested directly.
class CoordinatorOverview {
  /// Creates a coordinator overview.
  CoordinatorOverview({
    required this.students,
    required this.lecturers,
    required this.internships,
    required this.progress,
  });

  /// Every student, sorted by name.
  final List<UserModel> students;

  /// Every lecturer (approved and awaiting approval), sorted by name.
  final List<UserModel> lecturers;

  /// Every internship on record.
  final List<InternshipModel> internships;

  /// Progress counts, keyed by internship ID. Only placements that have
  /// started supervision (assigned, active, completed) are counted.
  final Map<String, InternshipProgress> progress;

  /// Statuses whose attendance, logbook, and visits are worth counting.
  static const trackedStatuses = {
    InternshipStatus.assigned,
    InternshipStatus.active,
    InternshipStatus.completed,
  };

  /// A student's current placement, or null if they have none.
  ///
  /// A student can have more than one record — typically a rejected
  /// placement followed by a successful resubmission — so a non-rejected
  /// record wins, and among equals the most recently created one does.
  InternshipModel? internshipFor(String studentId) {
    InternshipModel? best;
    for (final internship in internships) {
      if (internship.studentId != studentId) {
        continue;
      }
      if (best == null || _outranks(internship, best)) {
        best = internship;
      }
    }
    return best;
  }

  static bool _outranks(InternshipModel candidate, InternshipModel current) {
    final candidateRejected = candidate.status == InternshipStatus.rejected;
    final currentRejected = current.status == InternshipStatus.rejected;
    if (candidateRejected != currentRejected) {
      return currentRejected;
    }
    return candidate.createdAt.isAfter(current.createdAt);
  }

  /// Progress for an internship, or zeros if it isn't tracked yet.
  InternshipProgress progressFor(String internshipId) =>
      progress[internshipId] ?? InternshipProgress.empty;

  /// Placements supervised by a lecturer, excluding completed ones — the
  /// lecturer's current workload.
  List<InternshipModel> activeLoadFor(String lecturerId) => internships
      .where(
        (internship) =>
            internship.lecturerId == lecturerId &&
            (internship.status == InternshipStatus.assigned ||
                internship.status == InternshipStatus.active),
      )
      .toList();

  /// Every placement a lecturer has ever supervised.
  List<InternshipModel> allSupervisedBy(String lecturerId) => internships
      .where((internship) => internship.lecturerId == lecturerId)
      .toList();

  /// Lecturers who signed up and are waiting for approval.
  List<UserModel> get pendingLecturers =>
      lecturers.where((lecturer) => !lecturer.isActive).toList();

  /// Approved lecturers.
  List<UserModel> get activeLecturers =>
      lecturers.where((lecturer) => lecturer.isActive).toList();

  /// How many students' current placement is in each status, plus a
  /// `null` bucket for students with no placement at all.
  Map<InternshipStatus?, int> get statusCounts {
    final counts = <InternshipStatus?, int>{};
    for (final student in students) {
      final status = internshipFor(student.uid)?.status;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Every department that appears on a student, sorted, for filters.
  List<String> get departments =>
      (students.map((student) => student.department).toSet().toList())
        ..sort();
}
