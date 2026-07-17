import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = FlutterSecureStorage();

  Future<bool> autenticarBiometricamente() async {
    bool canCheck = await _auth.canCheckBiometrics;
    if (!canCheck) return false;
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Autentícate para realizar el pago',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  Future<void> guardarToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> eliminarToken() async {
    await _storage.delete(key: 'token');
  }

  Future<String?> obtenerToken() async {
    return await _storage.read(key: 'token');
  }
}