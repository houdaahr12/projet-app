import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _kEnabled = 'bio_enabled';
  static const _kIdentifiant = 'bio_identifiant';
  static const _kPassword = 'bio_password';

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scannez votre empreinte pour vous connecter',
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint('BIOMETRIC ERROR: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async =>
      (await _storage.read(key: _kEnabled)) == 'true';

  Future<void> enable({
    required String identifiant,
    required String motDePasse,
  }) async {
    await _storage.write(key: _kIdentifiant, value: identifiant);
    await _storage.write(key: _kPassword, value: motDePasse);
    await _storage.write(key: _kEnabled, value: 'true');
  }

  Future<Map<String, String>?> readCredentials() async {
    final id = await _storage.read(key: _kIdentifiant);
    final pw = await _storage.read(key: _kPassword);
    if (id == null || pw == null) return null;
    return {'identifiant': id, 'mot_de_passe': pw};
  }

  /// Only removes the fingerprint data, never the rest of the session.
  Future<void> disable() async {
    await _storage.delete(key: _kEnabled);
    await _storage.delete(key: _kIdentifiant);
    await _storage.delete(key: _kPassword);
  }
}
