import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/messaging/push_service.dart';

/// Week 6 Lab 2 debug screen for the FCM token.
///
/// HARD RULE: the token is rendered ONLY through [maskToken]
/// (first 12 characters + '...'). The full token must never appear
/// on screen, in logs, or in report screenshots.
class TokenDebugPage extends ConsumerWidget {
  const TokenDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Token debug')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key, size: 48),
              const SizedBox(height: 16),
              Text('FCM token (masked)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(
                token == null ? '(belum ada token)' : maskToken(token),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text(
                'Token penuh TIDAK BOLEH ditampilkan. '
                'Screenshot hanya boleh memperlihatkan versi ter-mask ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
