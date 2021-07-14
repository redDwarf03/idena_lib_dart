// @dart=2.9

// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Package imports:
import 'package:hex/hex.dart';
import 'package:sha3/sha3.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// Project imports:
import 'package:idena_lib_dart/pubdev/cryptography/algorithms/aes_gcm.dart';
import 'package:idena_lib_dart/pubdev/cryptography/nonce.dart';
import 'package:idena_lib_dart/pubdev/cryptography/secret_key.dart';

class UtilCrypto {
  Future<String> encryptedPrivateKeyToAddress(
      String encPrivateKey, String password) async {
    //print("encPrivateKey: " + encPrivateKey);
    //print("password: " + password);
    try {
      EthPrivateKey ethPrivateKey = EthPrivateKey.fromHex(
          await encryptedPrivateKeyToSeed(encPrivateKey, password));
      //print("ethPrivateKey: " + ethPrivateKey.privateKey.toString());
      if (ethPrivateKey.privateKey.length != 32) {
        return "";
      }
      //final address = await ethPrivateKey.extractAddress();
      var k = SHA3(256, KECCAK_PADDING, 256);
      k.update(privateKeyBytesToPublic(ethPrivateKey.privateKey));
      var hash = k.digest();
      int _shaBytes = 256 ~/ 8;
      hash = Uint8List.view(Uint8List.fromList(hash).buffer, _shaBytes - 20);

      EthereumAddress address = EthereumAddress(hash);

      //print("address.hex : " + address.hex);
      return address.hexEip55;
    } catch (e) {
      print(e);
      return "";
    }
  }

  Future<String> encryptedPrivateKeyToSeed(
      String encPrivateKey, String password) async {
    try {
      if (encPrivateKey.isNotEmpty ||
          password.isNotEmpty) {
        return "";
      }

      var k = SHA3(256, SHA3_PADDING, 256);
      k.update(utf8.encode(password));
      final key = Uint8List.fromList(k.digest());
      //print(" hash mdp = key: " + HEX.encode(key));
      //print(key);

      var dataArray = Uint8List.fromList(HEX.decode(encPrivateKey));
      //print("** dataArrayhex : " + encPrivateKey);
      if (dataArray.length < 12) {
        return "";
      }
      final dataArray0to12 = dataArray.sublist(0, 12);
      final cypherText = dataArray.sublist(12);
      //print("cypher : " + HEX.encode(cypherText));

      final iv = dataArray0to12;
      //print("iv : " + HEX.encode(iv));
      //print("aad : " + HEX.encode(aad));
      var secretKey = new SecretKey(key);
      Nonce nonce = new Nonce(iv);

      Uint8List decrypted =
          aesGcm.decryptSync(cypherText, secretKey: secretKey, nonce: nonce);
      //print("decrypted: " + HEX.encode(decrypted));

      return HEX.encode(decrypted);
    } catch (e) {
      return "";
    }
  }
}
