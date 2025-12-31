// Basic Flutter widget test for GrammarChecker app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:grammar_checker/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GrammarCheckerApp(),
      ),
    );

    // Verify that the app loads
    expect(find.byType(GrammarCheckerApp), findsOneWidget);
  });
}
