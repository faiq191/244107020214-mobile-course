import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model Tests', () {
    test('fromJson successfully parses complete json', () {
      final json = {
        'postId': 1,
        'id': 101,
        'name': 'John Doe',
        'email': 'john@example.com',
        'body': 'A helpful comment.',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 101);
      expect(comment.name, 'John Doe');
      expect(comment.email, 'john@example.com');
      expect(comment.body, 'A helpful comment.');
    });

    test('fromJson handles missing fields with safe default values', () {
      final json = <String, dynamic>{
        'postId': 2,
        // 'id', 'name', 'email', 'body' sengaja dihilangkan
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 2);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    // Edge case tambahan: null fields
    test('fromJson handles explicit null values safely', () {
      final json = <String, dynamic>{
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });
}
