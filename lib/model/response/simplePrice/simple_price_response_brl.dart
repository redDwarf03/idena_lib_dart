// @dart=2.9
// To parse this JSON data, do
//
//     final simplePriceBrlResponse = simplePriceBrlResponseFromJson(jsonString);

// Dart imports:
import 'dart:convert';

SimplePriceBrlResponse simplePriceBrlResponseFromJson(String str) =>
    SimplePriceBrlResponse.fromJson(json.decode(str));

String simplePriceBrlResponseToJson(SimplePriceBrlResponse data) =>
    json.encode(data.toJson());

class SimplePriceBrlResponse {
  SimplePriceBrlResponse({
    this.idena,
  });

  Idena idena;

  factory SimplePriceBrlResponse.fromJson(Map<String, dynamic> json) =>
      SimplePriceBrlResponse(
        idena: Idena.fromJson(json["idena"]),
      );

  Map<String, dynamic> toJson() => {
        "idena": idena.toJson(),
      };
}

class Idena {
  Idena({
    this.brl,
  });

  double brl;

  factory Idena.fromJson(Map<String, dynamic> json) => Idena(
        brl: json["brl"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "brl": brl,
      };
}
