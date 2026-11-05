// Lab 2 evidence tests (FINAL version — unchanged from red run to green run).
// Red run  : v1 use case calls String.contains(q, caseSensitive: false)
//            -> undefined_named_parameter, this file fails to compile.
// Green run: v2 use case compares lowercased strings -> all tests pass.
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/domain/usecases/filter_announcements.dart';

void main() {
  final fixtures = [
    const Announcement(
      id: 'a1',
      title: 'Ujian Algoritma',
      preview: 'Ruang 204, pukul 08.00 WIB',
    ),
    const Announcement(
      id: 'a2',
      title: 'Groceries Sale at Kantin',
      preview: 'Diskon 20% setiap Jumat',
    ),
    const Announcement(
      id: 'a3',
      title: 'Beasiswa Dalam Negeri 2026',
      preview: 'Pendaftaran dibuka 1 Juni',
    ),
    const Announcement(
      id: 'a4',
      title: 'Rundown GROCERIES Panitia',
      preview: 'Cek pantry list sebelum acara',
    ),
  ];

  group('filterAnnouncements (Lab 2 evidence)', () {
    test('filter ignores case', () {
      expect(filterAnnouncements(fixtures, 'groceries'), hasLength(2));
    });

    test('no-match query returns empty', () {
      expect(filterAnnouncements(fixtures, 'zzz-missing'), isEmpty);
    });

    test('empty or blank query returns all items', () {
      expect(filterAnnouncements(fixtures, ''), hasLength(4));
      expect(filterAnnouncements(fixtures, '   '), hasLength(4));
    });

    test('matches on title OR preview', () {
      final byPreview = filterAnnouncements(fixtures, 'ruang');
      expect(byPreview.map((a) => a.id), ['a1']);
    });
  });
}
