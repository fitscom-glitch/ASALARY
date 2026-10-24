import 'dart:convert';
import 'dart:math' as math;

const List<int> _k256 = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const List<int> _h256 = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

int _rotr32(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;

List<int> sha256Bytes(List<int> data) {
  final len = data.length;
  final padded = ((len + 9 + 63) ~/ 64) * 64;
  final msg = List<int>.filled(padded, 0);
  for (var i = 0; i < len; i++) {
    msg[i] = data[i] & 0xFF;
  }
  msg[len] = 0x80;
  final bits = len * 8;
  msg[padded - 4] = (bits >>> 24) & 0xFF;
  msg[padded - 3] = (bits >>> 16) & 0xFF;
  msg[padded - 2] = (bits >>> 8) & 0xFF;
  msg[padded - 1] = bits & 0xFF;

  var h0 = _h256[0], h1 = _h256[1], h2 = _h256[2], h3 = _h256[3];
  var h4 = _h256[4], h5 = _h256[5], h6 = _h256[6], h7 = _h256[7];
  final w = List<int>.filled(64, 0);

  for (var off = 0; off < padded; off += 64) {
    for (var i = 0; i < 16; i++) {
      final j = off + i * 4;
      w[i] = ((msg[j] << 24) | (msg[j + 1] << 16) | (msg[j + 2] << 8) | msg[j + 3]) & 0xFFFFFFFF;
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr32(w[i - 15], 7) ^ _rotr32(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rotr32(w[i - 2], 17) ^ _rotr32(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
    }
    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (var i = 0; i < 64; i++) {
      final bigS1 = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25);
      final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
      final t1 = (h + bigS1 + ch + _k256[i] + w[i]) & 0xFFFFFFFF;
      final bigS0 = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (bigS0 + maj) & 0xFFFFFFFF;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xFFFFFFFF;
    }
    h0 = (h0 + a) & 0xFFFFFFFF;
    h1 = (h1 + b) & 0xFFFFFFFF;
    h2 = (h2 + c) & 0xFFFFFFFF;
    h3 = (h3 + d) & 0xFFFFFFFF;
    h4 = (h4 + e) & 0xFFFFFFFF;
    h5 = (h5 + f) & 0xFFFFFFFF;
    h6 = (h6 + g) & 0xFFFFFFFF;
    h7 = (h7 + h) & 0xFFFFFFFF;
  }

  final out = <int>[];
  for (final v in [h0, h1, h2, h3, h4, h5, h6, h7]) {
    out
      ..add((v >>> 24) & 0xFF)
      ..add((v >>> 16) & 0xFF)
      ..add((v >>> 8) & 0xFF)
      ..add(v & 0xFF);
  }
  return out;
}

List<int> hmacSha256(List<int> key, List<int> msg) {
  var k = key.length > 64 ? sha256Bytes(key) : List<int>.of(key);
  k = [...k, ...List<int>.filled(64 - k.length, 0)];
  final ipad = [for (final b in k) b ^ 0x36];
  final opad = [for (final b in k) b ^ 0x5c];
  return sha256Bytes([...opad, ...sha256Bytes([...ipad, ...msg])]);
}

List<int> _pbkdf2(String password, List<int> salt, int iterations) {
  final key = utf8.encode(password);
  var u = hmacSha256(key, [...salt, 0, 0, 0, 1]);
  final t = List<int>.of(u);
  for (var i = 1; i < iterations; i++) {
    u = hmacSha256(key, u);
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return t;
}

abstract final class PasswordHasher {
  static const _iterations = 10000;

  /// Trả về chuỗi 'p1:số-vòng:muối:băm' (base64) để lưu; không lưu mật khẩu gốc.
  static String create(String password) {
    final rnd = math.Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final hash = _pbkdf2(password, salt, _iterations);
    return 'p1:$_iterations:${base64.encode(salt)}:${base64.encode(hash)}';
  }

  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 4 || parts[0] != 'p1') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1 || iterations > 1000000) return false;
    try {
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      final actual = _pbkdf2(password, salt, iterations);
      var diff = expected.length ^ actual.length;
      for (var i = 0; i < expected.length && i < actual.length; i++) {
        diff |= expected[i] ^ actual[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }
}
