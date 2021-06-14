// Dart imports:
import 'dart:typed_data';

// Project imports:
import 'package:idena_lib_dart/model/dictWords.dart';

class ValidationSessionInfoFlips {
  ValidationSessionInfoFlips(
      {this.hash,
      this.ready,
      this.extra,
      this.available,
      this.listWords,
      this.listImagesLeft,
      this.listImagesRight,
      this.answerType,
      this.relevanceType});

  String? hash;
  bool? ready;
  bool? extra;
  bool? available;
  List<Word>? listWords;
  List<Uint8List>? listImagesLeft;
  List<Uint8List>? listImagesRight;
  int? answerType;
  int? relevanceType;
}

class ValidationSessionInfo {
  ValidationSessionInfo(
      {this.typeSession, this.listSessionValidationFlips, this.privateKey});

  String? typeSession;
  String? privateKey;
  List<ValidationSessionInfoFlips>? listSessionValidationFlips;
  List<ValidationSessionInfoFlips>? listSessionValidationFlipsExtra;
}
