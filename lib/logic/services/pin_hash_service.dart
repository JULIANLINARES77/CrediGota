import 'package:flutter/services.dart';

class PinHashService {
  const PinHashService();

  static const _channel = MethodChannel('gotacontrol/pin_hash');
  static final _pinPattern = RegExp(r'^\d{4,6}$');

  Future<String> hash(String pin) async {
    if (!_pinPattern.hasMatch(pin)) {
      throw ArgumentError('El PIN debe tener entre 4 y 6 dígitos.');
    }
    final hash = await _channel.invokeMethod<String>('hashPin', {'pin': pin});
    if (hash == null || !hash.startsWith(r'$2a$12$')) {
      throw StateError('El servicio de seguridad devolvió un hash inválido.');
    }
    return hash;
  }

  Future<bool> verify(String pin, String hash) async {
    if (!_pinPattern.hasMatch(pin)) return false;
    final valid = await _channel.invokeMethod<bool>('verifyPin', {
      'pin': pin,
      'hash': hash,
    });
    if (valid == null) {
      throw StateError('El servicio de seguridad no devolvió un resultado.');
    }
    return valid;
  }
}

enum PinValidationResult { valid, invalid, locked }
