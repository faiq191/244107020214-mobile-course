import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

// Provider untuk CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(createDio());
});

// Fungsi pemetaan error menjadi pesan ramah pengguna
String friendlyCommentError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 404) return 'Comments not found (404).';
        if (status != null && status >= 500) {
          return 'Server error ($status). Please try again later.';
        }
        return 'Received invalid response ($status).';
      default:
        return 'A network error occurred. Please try again.';
    }
  }
  return 'An unexpected error occurred.';
}

// AsyncNotifierProvider dengan automatic error handling & custom refresh
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  int _currentPostId = 1;

  @override
  Future<List<Comment>> build() async {
    final repo = ref.read(commentRepositoryProvider);
    return repo.fetchComments(_currentPostId);
  }

  Future<void> fetchByPostId(int postId) async {
    _currentPostId = postId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(commentRepositoryProvider).fetchComments(postId);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(commentRepositoryProvider).fetchComments(_currentPostId);
    });
  }
}

final commentsNotifierProvider =
    AsyncNotifierProvider<CommentsNotifier, List<Comment>>(
      CommentsNotifier.new,
    );
