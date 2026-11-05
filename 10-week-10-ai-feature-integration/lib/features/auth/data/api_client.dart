import 'package:dio/dio.dart';

import '../domain/repositories/auth_repository.dart';
import 'token_store.dart';

/// Dio client with automatic token refresh on 401.
/// Flow: request -> 401 -> refresh -> retry once -> still 401 -> logout.
///
/// Lives in the auth feature's data layer because the refresh flow is an
/// auth concern; presentation code must never import this file directly —
/// other features reach the network through their own repositories.
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refresh = await store.readRefresh();
          if (refresh == null) return handler.next(e);
          try {
            final renewed = await auth.refresh(refresh);
            await store.save(access: renewed, refresh: refresh);
            final retry = await dio.fetch(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );
            return handler.resolve(retry);
          } catch (_) {
            await store.clear(); // refresh dead too -> force re-login
          }
        }
        handler.next(e);
      },
    ),
  );

  return dio;
}
