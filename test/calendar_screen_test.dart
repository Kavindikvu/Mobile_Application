import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillora_family/features/calendar/presentation/calendar_screen.dart';

void main() {
  testWidgets('Calendar screen renders and shows a title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CalendarScreen())));
    expect(find.text('Family Calendar'), findsOneWidget);
    await tester.pumpAndSettle();
    // Verify list renders without requiring specific icons on initial screen
    expect(find.byType(ListView), findsOneWidget);
  });
}


