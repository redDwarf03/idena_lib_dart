// Dart imports:
import 'dart:typed_data';

// Project imports:
import 'package:idena_lib_dart/util/encrypt/model/keyiv.dart';

/// KDF (Key derivator function) base class
abstract class KDF {
  /// Derive a KeyIV with given password and optional salt
  KeyIV deriveKey(String password, {Uint8List salt});
}
