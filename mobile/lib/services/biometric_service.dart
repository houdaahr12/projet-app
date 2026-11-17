import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to log in',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async =>
      (await _storage.read(key: 'bio_enabled')) == 'true';

  Future<void> enable({required String token, required String name}) async {
    await _storage.write(key: 'bio_enabled', value: 'true');
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'name', value: name);
  }

  Future<Map<String, String>?> readSession() async {
    final token = await _storage.read(key: 'token');
    final name = await _storage.read(key: 'name');
    if (token == null || name == null) return null;
    return {'token': token, 'name': name};
  }

  Future<void> disable() async => _storage.deleteAll();
}
