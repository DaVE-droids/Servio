import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/internship_progress.dart';
import '../services/reports_service.dart';

/// Repository for coordinator reporting data.
class ReportsRepository {
  /// Creates a reports repository.
  const ReportsRepository(this._service);

  final ReportsService _service;

  /// Loads progress counts for each internship ID, keyed by that ID.
  ///
  /// All counts run in parallel — four small queries per internship — so a
  /// report over fifty placements is a couple of hundred cheap aggregation
  /// reads that finish together, not a long sequential wait.
  Future<Result<Map<String, InternshipProgress>>> loadProgress(
    List<String> internshipIds,
  ) async {
    try {
      final entries = await Future.wait(
        internshipIds.map((id) async {
          final counts = await Future.wait([
            _service.countAttendance(id),
            _service.countLogbookEntries(id),
            _service.countApprovedLogbookEntries(id),
            _service.countVisits(id),
          ]);
          return MapEntry(
            id,
            InternshipProgress(
              attendanceDays: counts[0],
              logbookEntries: counts[1],
              logbookApproved: counts[2],
              visits: counts[3],
            ),
          );
        }),
      );
      return Success(Map.fromEntries(entries));
    } on FirebaseException catch (error) {
      return Failure(
        AppFailure(
          message: error.code == 'unavailable'
              ? 'Unable to connect. Check your internet connection and try again.'
              : 'Unable to load progress figures. Please try again.',
          type: error.code == 'unavailable'
              ? FailureType.network
              : FailureType.database,
          code: error.code,
          technicalDetails: error,
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Something unexpected happened. Please try again.',
          technicalDetails: error,
        ),
      );
    }
  }
}
