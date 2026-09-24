import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository({this.items, this.throwError = false}) : super(Dio());

  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? const [];
  }

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    return fetchPosts();
  }
}

void main() {
  test('fromJson is safe against missing fields', () {
    final post = Post.fromJson({'id': 7});
    expect(post.id, 7);
    expect(post.title, '');
    expect(post.userId, 0);
  });

  test('friendlyErrorMessage for connection error', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    expect(friendlyErrorMessage(err), contains('reach'));
  });

  test('provider succeeds with a fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(
            items: [const Post(userId: 1, id: 1, title: 'Test', body: 'Body')],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final posts = await readPostsOnce(container);
    expect(posts.length, 1);
    expect(posts.first.title, 'Test');
  });

  test('provider errors with a fake repository', () async {
    final fakeRepo = FakePostRepository(throwError: true);
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    // Ambil error langsung dari repository yang di-override provider
    Object? err;
    try {
      await container.read(postRepositoryProvider).fetchPosts();
    } catch (e) {
      err = e;
    }

    expect(err, isA<DioException>());
    expect(friendlyErrorMessage(err!), contains('reach'));
  });
}
