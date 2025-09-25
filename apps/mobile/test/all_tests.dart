import 'package:flutter_test/flutter_test.dart';

import 'services/auth_service_test.dart' as auth_service_tests;
import 'state/auth_controller_test.dart' as auth_controller_tests;
import 'features/navigation_test.dart' as navigation_tests;
import 'features/chat_test.dart' as chat_tests;

void main() {
  group('AIc Mobile App - All Tests', () {
    group('Service Tests', () {
      auth_service_tests.main();
    });

    group('State Management Tests', () {
      auth_controller_tests.main();
    });

    group('Navigation Tests', () {
      navigation_tests.main();
    });

    group('Chat Tests', () {
      chat_tests.main();
    });
  });
}