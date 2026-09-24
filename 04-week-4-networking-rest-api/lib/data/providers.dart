import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

export 'network_errors.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(createDio());
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  return await repository.fetchPosts();
});

// Helper pembaca untuk unit testing
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  return container.read(postsProvider.future);
}

Future<Object> readPostsErrorOnce(ProviderContainer container) async {
  // Paksa Riverpod menjalankan build
  final subscription = container.listen(postsProvider, (_, _) {});
  try {
    await container.read(postsProvider.future);
    throw StateError('Expected error but succeeded');
  } catch (e) {
    return e;
  } finally {
    subscription.close();
  }
}
