import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/auth/presentation/pages/login_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_notify/main.dart';

class _LoggedOutAuth extends AuthNotifier {
  @override
  Future<bool> build() async => false;
}

void main() {
  testWidgets('unauthenticated user lands on login page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith(_LoggedOutAuth.new)],
        child: const CampusNotifyApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
