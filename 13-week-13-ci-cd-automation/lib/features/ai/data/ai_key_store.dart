import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single gateway for the AI provider key.
///
/// The key never appears in source code, in Git, in the README or in a
/// screenshot. `flutter_secure_storage` uses the Android Keystore / iOS
/// Keychain; the value can be deleted from the assistant's key dialog.
class AiKeyStore {
  AiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'ai_api_key';

  Future<String?> read() => _storage.read(key: _apiKeyKey);

  Future<void> save(String apiKey) =>
      _storage.write(key: _apiKeyKey, value: apiKey);

  Future<void> clear() => _storage.delete(key: _apiKeyKey);

  Future<bool> hasKey() async {
    final key = await read();
    return key != null && key.trim().isNotEmpty;
  }
}
