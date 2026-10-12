import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// macOS Keychain options per D-009: legacy login keychain, no
/// keychain-access-groups, works under App Sandbox.
final macosOpts = MacOsOptions(usesDataProtectionKeychain: false);

/// Abstract store for the Google API key so tests can substitute a fake.
abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

/// Keychain-backed implementation for macOS.
class KeychainApiKeyStore implements ApiKeyStore {
  static const String _key = 'veliq.googleApiKey';

  final FlutterSecureStorage _storage;

  const KeychainApiKeyStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() => _storage.read(key: _key, mOptions: macosOpts);

  @override
  Future<void> write(String key) =>
      _storage.write(key: _key, value: key, mOptions: macosOpts);

  @override
  Future<void> delete() => _storage.delete(key: _key, mOptions: macosOpts);
}
