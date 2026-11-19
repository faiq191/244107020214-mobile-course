import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/ai_providers.dart';

/// Campus AI assistant: chat screen with a streaming answer, explicit loading
/// state, API-key setup, error/fallback path and a retry action.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(aiChatProvider.notifier).send(text);
  }

  Future<void> _showKeyDialog() async {
    final controller = TextEditingController();
    final configured = ref.read(aiKeyConfiguredProvider).value ?? false;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The key is stored in secure storage (Keystore/Keychain) and '
              'never sent anywhere except the AI provider.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('ai_key_field'),
              controller: controller,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Gemini API key',
                hintText: 'AIza…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          if (configured)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'remove'),
              child: const Text('Remove key'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('ai_key_save'),
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == 'save') {
      final key = controller.text.trim();
      if (key.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API key is empty — nothing saved.')),
          );
        }
      } else if (mounted) {
        await ref.read(aiRepositoryProvider).saveApiKey(key);
        if (mounted) {
          ref.invalidate(aiKeyConfiguredProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI API key saved securely.')),
          );
        }
      }
    } else if (result == 'remove') {
      await ref.read(aiRepositoryProvider).clearApiKey();
      ref.invalidate(aiKeyConfiguredProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('AI API key removed.')));
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final keyState = ref.watch(aiKeyConfiguredProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus AI Assistant'),
        actions: [
          IconButton(
            key: const Key('ai_settings_key'),
            tooltip: 'AI API key',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: _showKeyDialog,
          ),
          IconButton(
            key: const Key('ai_clear_chat'),
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => ref.read(aiChatProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (keyState.value == false) const _MissingKeyBanner(),
          Expanded(
            child: state.messages.isEmpty
                ? _Welcome(onSuggestion: _send)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: state.messages[index]),
                  ),
          ),
          if (state.hasFallback)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.error ?? 'The AI service is unavailable.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('ai_retry'),
                    onPressed: () => ref.read(aiChatProvider.notifier).retry(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ai_chat_input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: state.isStreaming ? null : _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about campus news…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('ai_chat_send'),
                    tooltip: 'Send',
                    onPressed: state.isStreaming
                        ? null
                        : () => _send(_input.text),
                    icon: state.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingKeyBanner extends StatelessWidget {
  const _MissingKeyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'No AI API key set. Tap the key icon to add one. Offline fallback '
        'still works from cached announcements.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'When is the midterm?',
      'Any library news?',
      'Summarize today’s announcements',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask Campus AI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Answers come from the AI provider and cached campus '
              'announcements. Sensitive data is redacted before sending.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map(
                    (text) => ActionChip(
                      label: Text(text, style: const TextStyle(fontSize: 12)),
                      onPressed: () => onSuggestion(text),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;
    final background = isUser
        ? scheme.primary
        : message.isFallback
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = isUser
        ? scheme.onPrimary
        : message.isFallback
        ? scheme.onTertiaryContainer
        : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isFallback) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 14, color: foreground),
                  const SizedBox(width: 4),
                  Text(
                    'Offline fallback',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (message.text.isEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking…', style: TextStyle(color: foreground)),
                ],
              )
            else
              Text(
                message.text,
                style: TextStyle(color: foreground, height: 1.35),
              ),
          ],
        ),
      ),
    );
  }
}
