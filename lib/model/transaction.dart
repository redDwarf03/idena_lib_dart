// @dart=2.9
// To parse this JSON data, do
//
//     final transaction = transactionFromJson(jsonString);

// Dart imports:
import 'dart:typed_data' show Uint8List;

// Package imports:
import 'package:convert/convert.dart' show hex;
import 'package:ecdsa/ecdsa.dart' as ecdsa;
import 'package:elliptic/elliptic.dart' as elliptic;
import 'package:hex/hex.dart' show HEX;
import 'package:sha3/sha3.dart';

// Project imports:
import 'package:idena_lib_dart/pubdev/ethereum_util/bytes.dart';
import 'package:idena_lib_dart/pubdev/ethereum_util/utils.dart';
import 'package:idena_lib_dart/util/helpers.dart';

import 'package:web3dart/crypto.dart' as crypto
    show hexToBytes, intToBytes, MsgSignature, sign;

// Project imports:
import 'package:idena_lib_dart/protos/models.pb.dart'
    show ProtoTransaction, ProtoTransaction_Data;

class Transaction {
  Transaction(nonce, epoch, type, to, amount, maxFee, tips, payload) {
    this.nonce = nonce == null ? 0 : nonce;
    this.epoch = epoch == null ? 0 : epoch;
    this.type = type == null ? 0 : type;
    this.to = to == null ? "" : to;
    this.amount = amount == null ? 0 : amount;
    this.maxFee = maxFee == null ? 0 : maxFee;
    this.tips = tips == null ? 0 : tips;
    this.payload = payload == null ? null : payload;
    this.signature = null;
  }

  var nonce;
  var epoch;
  var type;
  var to;
  var amount;
  var maxFee;
  var tips;
  var payload;
  var signature;

  String toHex() {
    return hex.encode(this.toBytes());
  }

  Uint8List toBytes() {
    ProtoTransaction transaction = new ProtoTransaction();
    transaction.data = this._createProtoTxData();
    if (this.signature != null) {
      transaction.signature = toBuffer(this.signature);
    }
    return transaction.writeToBuffer();
  }

  ProtoTransaction_Data _createProtoTxData() {
    ProtoTransaction_Data data = new ProtoTransaction_Data();
    if (this.nonce != null && this.amount != 0) {
      data.nonce = this.nonce;
    }
    if (this.epoch != null && this.amount != 0) {
      data.epoch = this.epoch;
    }
    if (this.type != null && this.type != 0) {
      data.type = this.type;
    }
    if (this.to != null) {
      data.to = toBuffer(this.to);
    }
    if (this.amount != null && this.amount != 0) {
      data.amount = AppHelpers.bigIntToBuffer(this.amount);
    }
    if (this.maxFee != null && this.maxFee != 0) {
      data.maxFee = intToBuffer(this.maxFee);
    }
    if (this.tips != null && this.tips != 0) {
      data.tips = intToBuffer(this.tips);
    }
    if (this.payload != null) {
      data.payload = toBuffer(this.payload);
    }

    return data;
  }

  Transaction sign(String privateKey) {
    //print("this._createProtoTxData().writeToBuffer() : " +
    //    this._createProtoTxData().toString());

    //print(hex.encode(this._createProtoTxData().writeToBuffer()));

    //Uint8List messageHash =
    //    crypto.keccak256(this._createProtoTxData().writeToBuffer());

    var k = SHA3(256, KECCAK_PADDING, 256);
    k.update(this._createProtoTxData().writeToBuffer());
    Uint8List messageHash = Uint8List.fromList(k.digest());
    print(privateKey);
    print(HEX.encode(messageHash));

    elliptic.PrivateKey priv =
        elliptic.PrivateKey.fromHex(elliptic.getSecp256k1(), privateKey);
    var sig = ecdsa.ethereumSign(priv, messageHash);
    this.signature = AppHelpers.hexToBytes(sig.toEthCompactHex());

    return this;
  }

  fromHex(var hex) {
    return this.fromBytes(toBuffer(hex));
  }

  Transaction fromBytes(bytes) {
    ProtoTransaction protoTx = ProtoTransaction.fromBuffer(bytes);
    ProtoTransaction_Data protoTxData = protoTx.data;
    this.nonce = protoTxData.nonce;
    this.epoch = protoTxData.epoch;
    this.type = protoTxData.type;
    this.to = AppHelpers.toHexString(protoTxData.to, true);

    this.amount = Uint8List.fromList(protoTxData.amount);
    this.maxFee = Uint8List.fromList(protoTxData.maxFee);
    this.tips = Uint8List.fromList(protoTxData.tips);
    this.payload = protoTxData.payload;
    this.signature = HEX.encode(protoTx.signature);

    return this;
  }
}
