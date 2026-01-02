import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillora_family/features/activity/presentation/activity_dashboard.dart';

void main() {
  testWidgets('Activity dashboard shows KPI cards', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ActivityDashboard())));
    expect(find.text('My Progress'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('GPA'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Assignments'), findsOneWidget);
  });
}


