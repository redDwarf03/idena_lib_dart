// @dart=2.9
// To parse this JSON data, do
//
//     final simplePricePlnResponse = simplePricePlnResponseFromJson(jsonString);

// Dart imports:
import 'dart:convert';

SimplePricePlnResponse simplePricePlnResponseFromJson(String str) =>
    SimplePricePlnResponse.fromJson(json.decode(str));

String simplePricePlnResponseToJson(SimplePricePlnResponse data) =>
    json.encode(data.toJson());

class SimplePricePlnResponse {
  SimplePricePlnResponse({
    this.idena,
  });

  Idena idena;

  factory SimplePricePlnResponse.fromJson(Map<String, dynamic> json) =>
      SimplePricePlnResponse(
        idena: Idena.fromJson(json["idena"]),
      );

  Map<String, dynamic> toJson() => {
        "idena": idena.toJson(),
      };
}

class Idena {
  Idena({
    this.pln,
  });

  double pln;

  factory Idena.fromJson(Map<String, dynamic> json) => Idena(
        pln: json["pln"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "pln": pln,
      };
}
