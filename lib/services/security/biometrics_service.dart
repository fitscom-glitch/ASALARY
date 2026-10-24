import 'package:local_auth/local_auth.dart' show AuthenticationOptions, LocalAuthentication;

/// Xác thực vân tay / khuôn mặt (local_auth).
class Biometrics {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> available() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
