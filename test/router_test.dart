import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillora_family/main.dart';

void main() {
  testWidgets('App builds and shows Home tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SkilloraFamilyApp()));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });
}
