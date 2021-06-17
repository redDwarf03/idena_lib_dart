// Dart imports:
import 'dart:convert';
import 'dart:io';

// Project imports:
import 'package:idena_lib_dart/model/response/coins_price_response.dart';
import 'package:idena_lib_dart/model/response/coins_response.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_aed.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_ars.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_aud.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_brl.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_btc.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_cad.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_chf.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_clp.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_cny.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_czk.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_dkk.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_eur.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_gbp.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_hkd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_huf.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_idr.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_ils.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_inr.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_jpy.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_krw.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_kwd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_mxn.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_myr.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_nok.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_nzd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_php.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_pkr.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_pln.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_rub.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_sar.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_sek.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_sgd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_thb.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_try.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_twd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_usd.dart';
import 'package:idena_lib_dart/model/response/simplePrice/simple_price_response_zar.dart';

class ApiCoinsService {
  Future<CoinsResponse> getCoinsResponse() async {
    CoinsResponse? coinsResponse;
    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient
          .getUrl(Uri.parse("https://api.coingecko.com/api/v3/coins/idena"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        coinsResponse = coinsResponseFromJson(reply);
      }
    } finally {
      httpClient.close();
    }
    return coinsResponse!;
  }

  Future<CoinsPriceResponse> getCoinsChart(String currency, int nbDays) async {
    CoinsPriceResponse? coinsPriceResponse;
    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          "https://api.coingecko.com/api/v3/coins/idena/market_chart?vs_currency=" +
              currency +
              "&days=" +
              nbDays.toString()));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        coinsPriceResponse = coinsPriceResponseFromJson(reply);
      }
    } finally {
      httpClient.close();
    }
    return coinsPriceResponse!;
  }

  Future<SimplePriceResponse> getSimplePrice(String currency) async {
    SimplePriceResponse simplePriceResponse = new SimplePriceResponse();
    simplePriceResponse.currency = currency;

    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=idena&vs_currencies=BTC"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        SimplePriceBtcResponse simplePriceBtcResponse =
            simplePriceBtcResponseFromJson(reply);
        simplePriceResponse.btcPrice = simplePriceBtcResponse.idena.btc;
      }

      request = await httpClient.getUrl(Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=idena&vs_currencies=" +
              currency));
      request.headers.set('content-type', 'application/json');
      response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        switch (currency.toUpperCase()) {
          case "ARS":
            SimplePriceArsResponse simplePriceLocalResponse =
                simplePriceArsResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.ars;
            break;
          case "AUD":
            SimplePriceAudResponse simplePriceLocalResponse =
                simplePriceAudResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.aud;
            break;
          case "BRL":
            SimplePriceBrlResponse simplePriceLocalResponse =
                simplePriceBrlResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.brl;
            break;
          case "CAD":
            SimplePriceCadResponse simplePriceLocalResponse =
                simplePriceCadResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.cad;
            break;
          case "CHF":
            SimplePriceChfResponse simplePriceLocalResponse =
                simplePriceChfResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.chf;
            break;
          case "CLP":
            SimplePriceClpResponse simplePriceLocalResponse =
                simplePriceClpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.clp;
            break;
          case "CNY":
            SimplePriceCnyResponse simplePriceLocalResponse =
                simplePriceCnyResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.cny;
            break;
          case "CZK":
            SimplePriceCzkResponse simplePriceLocalResponse =
                simplePriceCzkResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.czk;
            break;
          case "DKK":
            SimplePriceDkkResponse simplePriceLocalResponse =
                simplePriceDkkResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.dkk;
            break;
          case "EUR":
            SimplePriceEurResponse simplePriceLocalResponse =
                simplePriceEurResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.eur;
            break;
          case "GBP":
            SimplePriceGbpResponse simplePriceLocalResponse =
                simplePriceGbpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.gbp;
            break;
          case "HKD":
            SimplePriceHkdResponse simplePriceLocalResponse =
                simplePriceHkdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.hkd;
            break;
          case "HUF":
            SimplePriceHufResponse simplePriceLocalResponse =
                simplePriceHufResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.huf;
            break;
          case "IDR":
            SimplePriceIdrResponse simplePriceLocalResponse =
                simplePriceIdrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.idr;
            break;
          case "ILS":
            SimplePriceIlsResponse simplePriceLocalResponse =
                simplePriceIlsResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.ils;
            break;
          case "INR":
            SimplePriceInrResponse simplePriceLocalResponse =
                simplePriceInrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.inr;
            break;
          case "JPY":
            SimplePriceJpyResponse simplePriceLocalResponse =
                simplePriceJpyResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.jpy;
            break;
          case "KRW":
            SimplePriceKrwResponse simplePriceLocalResponse =
                simplePriceKrwResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.krw;
            break;
          case "KWD":
            SimplePriceKwdResponse simplePriceLocalResponse =
                simplePriceKwdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.kwd;
            break;
          case "MXN":
            SimplePriceMxnResponse simplePriceLocalResponse =
                simplePriceMxnResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.mxn;
            break;
          case "MYR":
            SimplePriceMyrResponse simplePriceLocalResponse =
                simplePriceMyrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.myr;
            break;
          case "NOK":
            SimplePriceNokResponse simplePriceLocalResponse =
                simplePriceNokResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.nok;
            break;
          case "NZD":
            SimplePriceNzdResponse simplePriceLocalResponse =
                simplePriceNzdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.nzd;
            break;
          case "PHP":
            SimplePricePhpResponse simplePriceLocalResponse =
                simplePricePhpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.php;
            break;
          case "PKR":
            SimplePricePkrResponse simplePriceLocalResponse =
                simplePricePkrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.pkr;
            break;
          case "PLN":
            SimplePricePlnResponse simplePriceLocalResponse =
                simplePricePlnResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.pln;
            break;
          case "RUB":
            SimplePriceRubResponse simplePriceLocalResponse =
                simplePriceRubResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.rub;
            break;
          case "SAR":
            SimplePriceSarResponse simplePriceLocalResponse =
                simplePriceSarResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.sar;
            break;
          case "SEK":
            SimplePriceSekResponse simplePriceLocalResponse =
                simplePriceSekResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.sek;
            break;
          case "SGD":
            SimplePriceSgdResponse simplePriceLocalResponse =
                simplePriceSgdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.sgd;
            break;
          case "THB":
            SimplePriceThbResponse simplePriceLocalResponse =
                simplePriceThbResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.thb;
            break;
          case "TRY":
            SimplePriceTryResponse simplePriceLocalResponse =
                simplePriceTryResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.tryl;
            break;
          case "TWD":
            SimplePriceTwdResponse simplePriceLocalResponse =
                simplePriceTwdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.twd;
            break;
          case "AED":
            SimplePriceAedResponse simplePriceLocalResponse =
                simplePriceAedResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.aed;
            break;
          case "ZAR":
            SimplePriceZarResponse simplePriceLocalResponse =
                simplePriceZarResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.zar;
            break;
          case "USD":
          default:
            SimplePriceUsdResponse simplePriceLocalResponse =
                simplePriceUsdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.idena.usd;
            break;
        }
      }
    } catch (e) {} finally {
      httpClient.close();
    }
    return simplePriceResponse;
  }
}
