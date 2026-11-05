// Week 10 prompt/privacy evidence.
//
// These tests are network-free: they prove what leaves the device BEFORE any
// HTTP call. The redaction rule is a pure domain function, so it can be
// enforced without mocking the AI provider.
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/ai/domain/usecases/build_campus_prompt.dart';
import 'package:campus_notify/features/ai/domain/usecases/offline_fallback.dart';

void main() {
  group('redactSensitiveData', () {
    test('removes NIK, phone, e-mail and secrets', () {
      const raw =
          'My NIK 3201234567890123, phone 081234567890, '
          'e-mail budi@example.com, password: hunter2';

      final safe = redactSensitiveData(raw);

      expect(safe, contains('[NIK_REDACTED]'));
      expect(safe, contains('[PHONE_REDACTED]'));
      expect(safe, contains('[EMAIL_REDACTED]'));
      expect(safe, contains('[SECRET_REDACTED]'));
      expect(safe, isNot(contains('3201234567890123')));
      expect(safe, isNot(contains('081234567890')));
      expect(safe, isNot(contains('budi@example.com')));
      expect(safe, isNot(contains('hunter2')));
    });

    test('removes a provider key that was pasted into the chat', () {
      const raw = 'here is my key AIzaFAKE_UNIT_TEST_KEY_000000000';
      final safe = redactSensitiveData(raw);

      expect(safe, contains('[API_KEY_REDACTED]'));
      expect(safe, isNot(contains('AIzaFAKE')));
    });

    test('counts the redactions for the UI hint', () {
      expect(countRedactions('081234567890 and 085612345678'), 2);
      expect(countRedactions('When is the midterm?'), 0);
    });
  });

  group('buildCampusPrompt', () {
    test('puts the system prompt, context and sanitized question in place', () {
      final prompt = buildCampusPrompt(
        'When is the midterm? Call me on 081234567890.',
        context: 'Midterm schedule posted — Monday, 08.00 WIB',
      );

      expect(prompt.systemPrompt, campusSystemPrompt);
      expect(prompt.userPrompt, contains('Campus announcement context:'));
      expect(prompt.userPrompt, contains('Midterm schedule posted'));
      expect(prompt.userPrompt, contains('When is the midterm?'));
      expect(prompt.userPrompt, contains('[PHONE_REDACTED]'));
      expect(prompt.userPrompt, isNot(contains('081234567890')));
      expect(prompt.redactions, 1);
    });

    test('truncates an oversized context to at most six lines', () {
      final context = List.generate(12, (i) => 'Announcement $i').join('\n');
      final prompt = buildCampusPrompt('Any news?', context: context);

      expect(prompt.userPrompt, contains('Announcement 5'));
      expect(prompt.userPrompt, isNot(contains('Announcement 6')));
    });

    test('validation rejects empty and oversized provider answers', () {
      expect(validateAiReply(''), isNull);
      expect(validateAiReply('   '), isNull);
      expect(validateAiReply('A' * 601), isNull);
      expect(validateAiReply('  The library is open until 2 AM.  '), isNotNull);
    });
  });

  group('offlineFallbackReply', () {
    test('matches cached context when the AI API is down', () {
      final reply = offlineFallbackReply('midterm', [
        'Midterm schedule posted — Monday, 08.00 WIB',
        'Library extended hours — open until 2 AM',
      ]);

      expect(reply, contains('Offline results'));
      expect(reply, contains('Midterm schedule posted'));
      expect(reply, isNot(contains('Library extended hours')));
    });

    test('points to the portal when nothing matches', () {
      final reply = offlineFallbackReply('parking permit', const [
        'Midterm schedule posted — Monday, 08.00 WIB',
      ]);

      expect(reply, contains('campus portal'));
    });
  });
}
