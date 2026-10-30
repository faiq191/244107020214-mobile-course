import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcement/data/models/announcement_model.dart';

void main() {
  group('AnnouncementModel.fromMap title validation', () {
    test('builds the entity for a valid row', () {
      final model = AnnouncementModel.fromMap(const {
        'id': '1',
        'title': 'Midterm schedule posted',
        'preview': 'The timetable is in the portal.',
      });

      expect(model.id, '1');
      expect(model.title, 'Midterm schedule posted');
      expect(model.preview, 'The timetable is in the portal.');
    });

    test('trims surrounding whitespace from the title', () {
      final model = AnnouncementModel.fromMap(const {
        'id': '2',
        'title': '  Library extended hours  ',
        'preview': 'Open until 2 AM.',
      });

      expect(model.title, 'Library extended hours');
    });

    test('throws when the title key is missing', () {
      expect(
        () => AnnouncementModel.fromMap(const {
          'id': '3',
          'preview': 'No title here.',
        }),
        throwsArgumentError,
      );
    });

    test('throws when the title is an empty string', () {
      expect(
        () => AnnouncementModel.fromMap(const {
          'id': '4',
          'title': '',
          'preview': 'Blank title.',
        }),
        throwsArgumentError,
      );
    });

    test('throws when the title is only whitespace', () {
      expect(
        () => AnnouncementModel.fromMap(const {
          'id': '5',
          'title': '   ',
          'preview': 'Whitespace title.',
        }),
        throwsArgumentError,
      );
    });

    test(
      'throws ArgumentError, not TypeError, when the title is not a String',
      () {
        expect(
          () => AnnouncementModel.fromMap(const {
            'id': '6',
            'title': 42,
            'preview': 'Numeric title.',
          }),
          throwsArgumentError,
        );
      },
    );
  });
}
