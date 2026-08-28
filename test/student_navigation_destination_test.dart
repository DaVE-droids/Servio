import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/constants/app_routes.dart';
import 'package:servio/features/dashboard/presentation/widgets/student_navigation_destination.dart';

void main() {
  test('defines the DSS student navigation order', () {
    expect(
      StudentNavigationDestination.values.map(
        (destination) => destination.label,
      ),
      ['Dashboard', 'Attendance', 'Logbook', 'Notifications', 'Profile'],
    );
  });

  test('selects the matching route index', () {
    expect(
      StudentNavigationDestination.selectedIndexForPath(
        AppRoutes.studentDashboard,
      ),
      0,
    );
    expect(
      StudentNavigationDestination.selectedIndexForPath(AppRoutes.profile),
      4,
    );
  });

  test('falls back to dashboard for unknown paths', () {
    expect(StudentNavigationDestination.selectedIndexForPath('/unknown'), 0);
  });
}
