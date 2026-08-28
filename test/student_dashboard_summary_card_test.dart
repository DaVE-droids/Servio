import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/theme/app_colors.dart';
import 'package:servio/features/dashboard/presentation/widgets/student_dashboard_summary_card.dart';

void main() {
  testWidgets('renders optional dashboard card action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentDashboardSummaryCard(
            title: 'Current Internship',
            value: 'Not submitted yet',
            description: 'Submit your placement details.',
            icon: Icons.business_center_outlined,
            color: AppColors.warning,
            actionLabel: 'Submit',
            onActionPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Submit'));

    expect(tapped, isTrue);
    expect(find.text('Current Internship'), findsOneWidget);
    expect(find.text('Not submitted yet'), findsOneWidget);
  });
}
