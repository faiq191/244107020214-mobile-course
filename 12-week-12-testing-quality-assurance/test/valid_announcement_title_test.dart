// Week 12 — Lab step 2: "Test the logic".
//
// Unit tests for the pure domain rule `isValidAnnouncementTitle`. No widget is
// rendered, no network is touched, so this is the fastest layer in the suite.
// The three cases below cover the happy path plus the two edge cases the
// codelab calls out (empty input and whitespace-only input).
//
// Follows Arrange / Act / Assert (codelab §3.2): each test prepares a value,
// calls the function under test, then asserts the result with `expect`.
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcement/domain/usecases/validate_announcement_title.dart';

void main() {
  group('isValidAnnouncementTitle', () {
    test('accepts a title with text', () {
      // Arrange
      const title = 'Learn Flutter';
      // Act
      final result = isValidAnnouncementTitle(title);
      // Assert
      expect(result, isTrue);
    });

    test('accepts a title with surrounding whitespace', () {
      expect(isValidAnnouncementTitle('  Midterm schedule  '), isTrue);
    });

    test('rejects an empty string', () {
      expect(isValidAnnouncementTitle(''), isFalse);
    });

    test('rejects a whitespace-only string (edge case)', () {
      expect(isValidAnnouncementTitle('   '), isFalse);
      expect(isValidAnnouncementTitle('\t\n  '), isFalse);
    });
  });
}
