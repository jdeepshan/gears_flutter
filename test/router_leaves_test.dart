import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gears_flutter/core/router/app_router.dart';

void main() {
  testWidgets('leave routes are registered', (tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    final config = AppRouter.router.configuration;

    final listMatch = config.findMatch(Uri.parse('/leaves'));
    final detailMatch = config.findMatch(Uri.parse('/leaves/2400'));

    expect(listMatch.isNotEmpty, true, reason: '/leaves should match');
    expect(detailMatch.isNotEmpty, true, reason: '/leaves/2400 should match');
    expect(detailMatch.last.matchedLocation, '/leaves/2400');
  });
}
