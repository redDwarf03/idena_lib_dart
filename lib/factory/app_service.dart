// @dart=2.9

// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

// Project imports:
import 'package:idena_lib_dart/deepLinks/deepLinkParamSignin.dart';
import 'package:idena_lib_dart/deepLinks/idena_url.dart';
import 'package:idena_lib_dart/enums/epoch_period.dart' as EpochPeriod;
import 'package:idena_lib_dart/model/node_type.dart';
import 'package:idena_lib_dart/model/request/bcn_fee_per_gas_request.dart';
import 'package:idena_lib_dart/model/request/bcn_mempool_request.dart';
import 'package:idena_lib_dart/model/request/bcn_send_raw_tx_request.dart';
import 'package:idena_lib_dart/model/request/bcn_syncing_request.dart';
import 'package:idena_lib_dart/model/request/bcn_transaction_request.dart';
import 'package:idena_lib_dart/model/request/bcn_transactions_request.dart';
import 'package:idena_lib_dart/model/request/dna_activate_invite_request.dart';
import 'package:idena_lib_dart/model/request/dna_becomeOffline_request.dart';
import 'package:idena_lib_dart/model/request/dna_becomeOnline_request.dart';
import 'package:idena_lib_dart/model/request/dna_ceremonyIntervals_request.dart';
import 'package:idena_lib_dart/model/request/dna_getBalance_request.dart';
import 'package:idena_lib_dart/model/request/dna_getCoinbaseAddr_request.dart';
import 'package:idena_lib_dart/model/request/dna_getEpoch_request.dart';
import 'package:idena_lib_dart/model/request/dna_identity_request.dart';
import 'package:idena_lib_dart/model/request/dna_sendTransaction_request.dart';
import 'package:idena_lib_dart/model/request/dna_send_invite_request.dart';
import 'package:idena_lib_dart/model/request/dna_signin_request.dart';
import 'package:idena_lib_dart/model/response/api_get_address_response.dart';
import 'package:idena_lib_dart/model/response/bcn_fee_per_gas_response.dart';
import 'package:idena_lib_dart/model/response/bcn_mempool_response.dart';
import 'package:idena_lib_dart/model/response/bcn_send_raw_tx_response.dart';
import 'package:idena_lib_dart/model/response/bcn_syncing_response.dart';
import 'package:idena_lib_dart/model/response/bcn_transaction_response.dart';
import 'package:idena_lib_dart/model/response/bcn_transactions_response.dart';
import 'package:idena_lib_dart/model/response/dna_activate_invite_response.dart';
import 'package:idena_lib_dart/model/response/dna_becomeOffline_response.dart';
import 'package:idena_lib_dart/model/response/dna_becomeOnline_response.dart';
import 'package:idena_lib_dart/model/response/dna_ceremonyIntervals_response.dart';
import 'package:idena_lib_dart/model/response/dna_getBalance_response.dart';
import 'package:idena_lib_dart/model/response/dna_getCoinbaseAddr_response.dart';
import 'package:idena_lib_dart/model/response/dna_getEpoch_response.dart';
import 'package:idena_lib_dart/model/response/dna_identity_response.dart';
import 'package:idena_lib_dart/model/response/dna_sendTransaction_response.dart';
import 'package:idena_lib_dart/model/response/dna_send_invite_response.dart';
import 'package:idena_lib_dart/model/response/dna_signin_response.dart';
import 'package:idena_lib_dart/model/transaction.dart' as model;
import 'package:idena_lib_dart/pubdev/dartssh/client.dart';
import 'package:idena_lib_dart/pubdev/dartssh/http.dart' as ssh;
import 'package:idena_lib_dart/pubdev/ethereum_util/bytes.dart';
import 'package:idena_lib_dart/util/helpers.dart';
import 'package:idena_lib_dart/util/util_demo_mode.dart';
import 'package:idena_lib_dart/util/util_vps.dart';

class AppService {
  var logger = Logger();
  final Map<String, String> requestHeaders = {
    'Content-type': 'application/json',
  };

  AppService({this.nodeType, this.apiUrl, this.keyApp});

  int nodeType;
  String apiUrl;
  String keyApp;

  SSHClient sshClient;

  Future<DnaGetBalanceResponse> getBalanceGetResponse(String address) async {
    DnaGetBalanceRequest dnaGetBalanceRequest;
    DnaGetBalanceResponse dnaGetBalanceResponse = new DnaGetBalanceResponse();
    Map<String, dynamic> mapParams;

    Completer<DnaGetBalanceResponse> _completer =
        new Completer<DnaGetBalanceResponse>();

    if (this.nodeType == DEMO_NODE) {
      dnaGetBalanceResponse = new DnaGetBalanceResponse();
      dnaGetBalanceResponse.result = new DnaGetBalanceResponseResult();
      dnaGetBalanceResponse.result.balance = DM_PORTOFOLIO_MAIN;
      dnaGetBalanceResponse.result.stake = DM_PORTOFOLIO_STAKE;
    } else {
      if (this.nodeType == PUBLIC_NODE) {
        mapParams = {
          'method': DnaGetBalanceRequest.METHOD_NAME,
          'params': [address],
          'id': 101,
        };
      } else {
        mapParams = {
          'method': DnaGetBalanceRequest.METHOD_NAME,
          'params': [address],
          'id': 101,
          'key': this.keyApp
        };
      }

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaGetBalanceResponse =
                dnaGetBalanceResponseFromJson(response.text);
          }
        } else {
          dnaGetBalanceRequest = DnaGetBalanceRequest.fromJson(mapParams);
          String body = json.encode(dnaGetBalanceRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaGetBalanceResponse =
                dnaGetBalanceResponseFromJson(responseHttp.body);
          }
        }
      } catch (e) {
        logger.e(e.toString());
      }
    }

    _completer.complete(dnaGetBalanceResponse);

    return _completer.future;
  }

  Future<int> getLastNonce(String address) async {
    DnaGetBalanceResponse dnaGetBalanceResponse = new DnaGetBalanceResponse();
    dnaGetBalanceResponse = await getBalanceGetResponse(address);

    Completer<int> _completer = new Completer<int>();

    if (dnaGetBalanceResponse != null &&
        dnaGetBalanceResponse.result != null &&
        dnaGetBalanceResponse.result.nonce != null) {
      _completer.complete(dnaGetBalanceResponse.result.nonce);
    } else {
      _completer.complete(1);
    }

    return _completer.future;
  }

  Future<BcnTransactionsResponse> getAddressTxsResponse(
      String address, int count) async {
    Completer<BcnTransactionsResponse> _completer =
        new Completer<BcnTransactionsResponse>();

    Map<String, dynamic> mapParams;
    BcnTransactionsRequest bcnTransactionsRequest;
    BcnTransactionsResponse bcnTransactionsResponse;

    if (this.nodeType == DEMO_NODE) {
      bcnTransactionsResponse = new BcnTransactionsResponse();
      bcnTransactionsResponse.result = new BcnTransactionsResponseResult();
    } else {
      mapParams = {
        'method': BcnTransactionsRequest.METHOD_NAME,
        "params": [
          {"address": address, "count": count}
        ],
        'id': 101,
        'key': this.keyApp
      };

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            bcnTransactionsResponse =
                bcnTransactionsResponseFromJson(response.text);
          }
        } else {
          bcnTransactionsRequest = BcnTransactionsRequest.fromJson(mapParams);
          String body = json.encode(bcnTransactionsRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            bcnTransactionsResponse =
                bcnTransactionsResponseFromJson(responseHttp.body);
          }
        }

        List<Transaction> listTxsMempool =
            List<Transaction>.empty(growable: true);
        BcnMempoolResponse bcnMempoolResponse = await getMemPool(address);
        if (bcnMempoolResponse != null && bcnMempoolResponse.result != null) {
          List<String> hashList = bcnMempoolResponse.result;
          if (hashList != null) {
            for (int i = 0; i < hashList.length; i++) {
              BcnTransactionResponse bcnTransactionResponse =
                  await getTransaction(hashList[i], address);
              if (bcnTransactionResponse != null &&
                  bcnTransactionResponse.result != null) {
                Transaction transaction = new Transaction();
                transaction.amount = bcnTransactionResponse.result.amount;
                transaction.blockHash = bcnTransactionResponse.result.blockHash;
                transaction.epoch = bcnTransactionResponse.result.epoch;
                transaction.from = bcnTransactionResponse.result.from;
                transaction.hash = bcnTransactionResponse.result.hash;
                transaction.maxFee = bcnTransactionResponse.result.maxFee;
                transaction.nonce = bcnTransactionResponse.result.nonce;
                transaction.payload = bcnTransactionResponse.result.payload;
                transaction.timestamp = bcnTransactionResponse.result.timestamp;
                transaction.tips = bcnTransactionResponse.result.tips;
                transaction.to = bcnTransactionResponse.result.to;
                transaction.type = bcnTransactionResponse.result.type;
                transaction.usedFee = bcnTransactionResponse.result.usedFee;
                listTxsMempool.add(transaction);
              }
            }
          }
        }

        if (bcnTransactionsResponse != null &&
            bcnTransactionsResponse.result != null &&
            bcnTransactionsResponse.result.transactions != null) {
          bcnTransactionsResponse.result.transactions = new List.from(
              bcnTransactionsResponse.result.transactions.reversed);
          if (listTxsMempool.isNotEmpty) {
            bcnTransactionsResponse.result.transactions.addAll(listTxsMempool);
          }
        }
      } catch (e) {
        logger.e(e.toString());
      }
    }

    _completer.complete(bcnTransactionsResponse);

    return _completer.future;
  }

  Future<String> getWStatusGetResponse() async {
    DnaIdentityRequest dnaIdentityRequest;

    Map<String, dynamic> mapParams;
    Completer<String> _completer = new Completer<String>();

    if (this.nodeType == DEMO_NODE) {
      _completer.complete("true");
      return _completer.future;
    }

    mapParams = {
      'method': DnaIdentityRequest.METHOD_NAME,
      'params': [],
      'id': 101,
      'key': this.keyApp
    };

    try {
      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        } else {
          _completer.complete(sshClientStatus.sshClientStatusMsg);
          return _completer.future;
        }

        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          DnaIdentityResponse dnaIdentityResponse =
              dnaIdentityResponseFromJson(response.text);
          if (dnaIdentityResponse.result == null) {
            if (dnaIdentityResponse.error == null) {
              _completer.complete(response.text);
            } else {
              _completer.complete(dnaIdentityResponse.error.message);
            }
          } else {
            _completer.complete("true");
          }
        }
      } else {
        dnaIdentityRequest = DnaIdentityRequest.fromJson(mapParams);
        String body = json.encode(dnaIdentityRequest.toJson());
        http.Response responseHttp = await http
            .post(Uri.parse(this.apiUrl), body: body, headers: requestHeaders)
            .timeout(Duration(seconds: 2));
        if (responseHttp.statusCode == 200) {
          DnaIdentityResponse dnaIdentityResponse =
              dnaIdentityResponseFromJson(responseHttp.body);
          if (dnaIdentityResponse.result == null) {
            if (dnaIdentityResponse.error == null) {
              _completer.complete(responseHttp.body);
            } else {
              _completer.complete(dnaIdentityResponse.error.message);
            }
          } else {
            _completer.complete("true");
          }
        }
      }
    } catch (e) {
      _completer.complete(e.toString());
    }

    return _completer.future;
  }

  Future<DnaGetCoinbaseAddrResponse> getDnaGetCoinbaseAddr(
      String addressByDefault) async {
    DnaGetCoinbaseAddrRequest dnaGetCoinbaseAddrRequest;
    DnaGetCoinbaseAddrResponse dnaGetCoinbaseAddrResponse;
    Map<String, dynamic> mapParams;

    Completer<DnaGetCoinbaseAddrResponse> _completer =
        new Completer<DnaGetCoinbaseAddrResponse>();

    if (this.nodeType == DEMO_NODE) {
      dnaGetCoinbaseAddrResponse.result = DM_IDENTITY_ADDRESS;
    } else {
      mapParams = {
        'method': DnaGetCoinbaseAddrRequest.METHOD_NAME,
        'params': [],
        'id': 101,
        'key': this.keyApp
      };

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaGetCoinbaseAddrResponse =
                dnaGetCoinbaseAddrResponseFromJson(response.text);
          }
        } else {
          dnaGetCoinbaseAddrRequest =
              DnaGetCoinbaseAddrRequest.fromJson(mapParams);
          String body = json.encode(dnaGetCoinbaseAddrRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaGetCoinbaseAddrResponse =
                dnaGetCoinbaseAddrResponseFromJson(responseHttp.body);
          }
        }
      } catch (e) {
        logger.e(e.toString());
        dnaGetCoinbaseAddrResponse = new DnaGetCoinbaseAddrResponse();
        dnaGetCoinbaseAddrResponse.result = addressByDefault;
      }
    }
    _completer.complete(dnaGetCoinbaseAddrResponse);

    return _completer.future;
  }

  Future<DnaIdentityResponse> getDnaIdentity(String address) async {
    DnaIdentityRequest dnaIdentityRequest;
    DnaIdentityResponse dnaIdentityResponse;
    Map<String, dynamic> mapParams;

    Completer<DnaIdentityResponse> _completer =
        new Completer<DnaIdentityResponse>();

    if (address == null) {
      dnaIdentityResponse = new DnaIdentityResponse();
      dnaIdentityResponse.result = DnaIdentityResponseResult();
      _completer.complete(dnaIdentityResponse);
      return _completer.future;
    }

    if (this.nodeType == DEMO_NODE) {
      dnaIdentityResponse = new DnaIdentityResponse();
      dnaIdentityResponse.result = DnaIdentityResponseResult();
      dnaIdentityResponse.result.address = DM_IDENTITY_ADDRESS;
      dnaIdentityResponse.result.age = DM_IDENTITY_AGE;
      dnaIdentityResponse.result.state = DM_IDENTITY_STATE;
      dnaIdentityResponse.result.online = DM_IDENTITY_ONLINE;
      dnaIdentityResponse.result.flips = new List(DM_IDENTITY_MADE_FLIPS);
      dnaIdentityResponse.result.availableFlips =
          DM_IDENTITY_REQUIRED_FLIPS - DM_IDENTITY_MADE_FLIPS;
      dnaIdentityResponse.result.madeFlips = DM_IDENTITY_MADE_FLIPS;
      dnaIdentityResponse.result.requiredFlips = DM_IDENTITY_REQUIRED_FLIPS;
      dnaIdentityResponse.result.penalty = DM_IDENTITY_PENALTY;
      dnaIdentityResponse.result.invites = DM_INVITES;
      dnaIdentityResponse.result.totalQualifiedFlips =
          DM_IDENTITY_TOTAL_QUALIFIED_FLIPS;
      dnaIdentityResponse.result.totalShortFlipPoints =
          DM_IDENTITY_TOTAL_SHORT_FLIP_POINTS;
      List<int> _listWords1 = [DM_IDENTITY_KEYWORD_1, DM_IDENTITY_KEYWORD_2];
      dnaIdentityResponse.result.flipKeyWordPairs =
          List<FlipKeyWordPair>.empty(growable: true);
      dnaIdentityResponse.result.flipKeyWordPairs
          .add(new FlipKeyWordPair(id: 1, words: _listWords1, used: false));
      List<int> _listWords2 = [DM_IDENTITY_KEYWORD_3, DM_IDENTITY_KEYWORD_4];
      dnaIdentityResponse.result.flipKeyWordPairs
          .add(new FlipKeyWordPair(id: 1, words: _listWords2, used: false));
    } else {
      if (this.nodeType == PUBLIC_NODE) {
        mapParams = {
          'method': DnaIdentityRequest.METHOD_NAME,
          'params': [address],
          'id': 101,
        };
      } else {
        mapParams = {
          'method': DnaIdentityRequest.METHOD_NAME,
          'params': [address],
          'id': 101,
          'key': this.keyApp
        };
      }

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaIdentityResponse = dnaIdentityResponseFromJson(response.text);
          }
        } else {
          dnaIdentityRequest = DnaIdentityRequest.fromJson(mapParams);
          String body = json.encode(dnaIdentityRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaIdentityResponse =
                dnaIdentityResponseFromJson(responseHttp.body);
          }
        }
      } catch (e) {
        //logger.e(e.toString());
        dnaIdentityResponse = new DnaIdentityResponse();
        dnaIdentityResponse.result = DnaIdentityResponseResult();
        dnaIdentityResponse.result.address = address;
      }
    }
    _completer.complete(dnaIdentityResponse);

    return _completer.future;
  }

  Future<DnaGetEpochResponse> getDnaGetEpoch() async {
    DnaGetEpochRequest dnaGetEpochRequest;
    DnaGetEpochResponse dnaGetEpochResponse;

    Map<String, dynamic> mapParams;

    Completer<DnaGetEpochResponse> _completer =
        new Completer<DnaGetEpochResponse>();

    if (this.nodeType == DEMO_NODE) {
      dnaGetEpochResponse = new DnaGetEpochResponse();
      dnaGetEpochResponse.result = new DnaGetEpochResponseResult();
      dnaGetEpochResponse.result.currentPeriod = DM_EPOCH_CURRENT_PERIOD;
      dnaGetEpochResponse.result.epoch = DM_EPOCH_EPOCH;
      dnaGetEpochResponse.result.nextValidation = DM_EPOCH_NEXT_VALIDATION;
    } else {
      if (this.nodeType == PUBLIC_NODE) {
        mapParams = {
          'method': DnaGetEpochRequest.METHOD_NAME,
          'params': [],
          'id': 101,
        };
      } else {
        mapParams = {
          'method': DnaGetEpochRequest.METHOD_NAME,
          'params': [],
          'id': 101,
          'key': this.keyApp
        };
      }

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaGetEpochResponse = dnaGetEpochResponseFromJson(response.text);
          }
        } else {
          dnaGetEpochRequest = DnaGetEpochRequest.fromJson(mapParams);
          String body = json.encode(dnaGetEpochRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaGetEpochResponse =
                dnaGetEpochResponseFromJson(responseHttp.body);
          }
        }
      } catch (e) {
        logger.e(e.toString());
      }
    }

    _completer.complete(dnaGetEpochResponse);
    return _completer.future;
  }

  Future<DnaCeremonyIntervalsResponse> getDnaCeremonyIntervals() async {
    DnaCeremonyIntervalsRequest dnaCeremonyIntervalsRequest;
    DnaCeremonyIntervalsResponse dnaCeremonyIntervalsResponse;

    Map<String, dynamic> mapParams;

    Completer<DnaCeremonyIntervalsResponse> _completer =
        new Completer<DnaCeremonyIntervalsResponse>();

    if (this.nodeType == DEMO_NODE || this.nodeType == PUBLIC_NODE) {
      dnaCeremonyIntervalsResponse = new DnaCeremonyIntervalsResponse();
      dnaCeremonyIntervalsResponse.result =
          new DnaCeremonyIntervalsResponseResult();
      dnaCeremonyIntervalsResponse.result.flipLotteryDuration =
          DM_CEREMONY_INTERVALS_FLIP_LOTTERY_DURATION;
      dnaCeremonyIntervalsResponse.result.longSessionDuration =
          DM_CEREMONY_INTERVALS_LONG_SESSION_DURATION;
      dnaCeremonyIntervalsResponse.result.shortSessionDuration =
          DM_CEREMONY_INTERVALS_SHORT_SESSION_DURATION;
    } else {
      if (this.nodeType == PUBLIC_NODE) {
        mapParams = {
          'method': DnaCeremonyIntervalsRequest.METHOD_NAME,
          'params': [],
          'id': 101,
        };
      } else {
        mapParams = {
          'method': DnaCeremonyIntervalsRequest.METHOD_NAME,
          'params': [],
          'id': 101,
          'key': this.keyApp
        };
      }

      try {
        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaCeremonyIntervalsResponse =
                dnaCeremonyIntervalsResponseFromJson(response.text);
            if (dnaCeremonyIntervalsResponse.result == null) {
              dnaCeremonyIntervalsResponse.result =
                  new DnaCeremonyIntervalsResponseResult();
              dnaCeremonyIntervalsResponse.result.flipLotteryDuration =
                  DM_CEREMONY_INTERVALS_FLIP_LOTTERY_DURATION;
              dnaCeremonyIntervalsResponse.result.longSessionDuration =
                  DM_CEREMONY_INTERVALS_LONG_SESSION_DURATION;
              dnaCeremonyIntervalsResponse.result.shortSessionDuration =
                  DM_CEREMONY_INTERVALS_SHORT_SESSION_DURATION;
            }
          }
        } else {
          dnaCeremonyIntervalsRequest =
              DnaCeremonyIntervalsRequest.fromJson(mapParams);
          String body = json.encode(dnaCeremonyIntervalsRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaCeremonyIntervalsResponse =
                dnaCeremonyIntervalsResponseFromJson(responseHttp.body);
            if (dnaCeremonyIntervalsResponse.result == null) {
              dnaCeremonyIntervalsResponse.result =
                  new DnaCeremonyIntervalsResponseResult();
              dnaCeremonyIntervalsResponse.result.flipLotteryDuration =
                  DM_CEREMONY_INTERVALS_FLIP_LOTTERY_DURATION;
              dnaCeremonyIntervalsResponse.result.longSessionDuration =
                  DM_CEREMONY_INTERVALS_LONG_SESSION_DURATION;
              dnaCeremonyIntervalsResponse.result.shortSessionDuration =
                  DM_CEREMONY_INTERVALS_SHORT_SESSION_DURATION;
            }
          }
        }
      } catch (e) {
        logger.e(e.toString());
      }
    }

    _completer.complete(dnaCeremonyIntervalsResponse);

    return _completer.future;
  }

  Future<String> getCurrentPeriod() async {
    String currentPeriod = "";
    Completer<String> _completer = new Completer<String>();

    Map<String, dynamic> mapParams;

    try {
      DnaGetEpochRequest dnaGetEpochRequest;
      DnaGetEpochResponse dnaGetEpochResponse;
      if (this.nodeType == DEMO_NODE) {
        currentPeriod = DM_EPOCH_CURRENT_PERIOD;
      } else {
        mapParams = {
          'method': DnaGetEpochRequest.METHOD_NAME,
          'params': [],
          'id': 101,
          'key': this.keyApp
        };

        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            dnaGetEpochResponse = dnaGetEpochResponseFromJson(response.text);
            if (dnaGetEpochResponse.result != null) {
              currentPeriod = dnaGetEpochResponse.result.currentPeriod;
            } else {
              currentPeriod = EpochPeriod.None;
            }
          }
        } else {
          dnaGetEpochRequest = DnaGetEpochRequest.fromJson(mapParams);
          String body = json.encode(dnaGetEpochRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaGetEpochResponse =
                dnaGetEpochResponseFromJson(responseHttp.body);
            if (dnaGetEpochResponse.result != null) {
              currentPeriod = dnaGetEpochResponse.result.currentPeriod;
            } else {
              currentPeriod = EpochPeriod.None;
            }
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
      currentPeriod = EpochPeriod.None;
    }

    _completer.complete(currentPeriod);
    return _completer.future;
  }

  Future<DnaBecomeOnlineResponse> becomeOnline() async {
    DnaBecomeOnlineResponse dnaBecomeOnlineResponse;
    DnaBecomeOnlineRequest dnaBecomeOnlineRequest;

    Map<String, dynamic> mapParams;

    Completer<DnaBecomeOnlineResponse> _completer =
        new Completer<DnaBecomeOnlineResponse>();

    try {
      mapParams = {
        'method': DnaBecomeOnlineRequest.METHOD_NAME,
        "params": [
          {"nonce": null, "epoch": null}
        ],
        'id': 101,
        'key': this.keyApp
      };

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaBecomeOnlineResponse =
              dnaBecomeOnlineResponseFromJson(response.text);
        }
      } else {
        dnaBecomeOnlineRequest = DnaBecomeOnlineRequest.fromJson(mapParams);
        String body = json.encode(dnaBecomeOnlineRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          dnaBecomeOnlineResponse =
              dnaBecomeOnlineResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(dnaBecomeOnlineResponse);
    return _completer.future;
  }

  Future<DnaBecomeOfflineResponse> becomeOffline() async {
    DnaBecomeOfflineResponse dnaBecomeOffLineResponse;
    DnaBecomeOfflineRequest dnaBecomeOffLineRequest;

    Map<String, dynamic> mapParams;

    Completer<DnaBecomeOfflineResponse> _completer =
        new Completer<DnaBecomeOfflineResponse>();

    try {
      mapParams = {
        'method': DnaBecomeOfflineRequest.METHOD_NAME,
        "params": [
          {"nonce": null, "epoch": null}
        ],
        'id': 101,
        'key': this.keyApp
      };

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaBecomeOffLineResponse =
              dnaBecomeOfflineResponseFromJson(response.text);
        }
      } else {
        dnaBecomeOffLineRequest = DnaBecomeOfflineRequest.fromJson(mapParams);
        String body = json.encode(dnaBecomeOffLineRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          dnaBecomeOffLineResponse =
              dnaBecomeOfflineResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(dnaBecomeOffLineResponse);
    return _completer.future;
  }

  Future<DnaSendTransactionResponse> sendTip(
      String from, String amount, String seed) async {
    DnaSendTransactionResponse dnaSendTransactionResponse;
    Completer<DnaSendTransactionResponse> _completer =
        new Completer<DnaSendTransactionResponse>();

    dnaSendTransactionResponse = await sendTx(
        from, amount, "0xf429e36D68BE10428D730784391589572Ee0f72B", seed, null);

    _completer.complete(dnaSendTransactionResponse);
    return _completer.future;
  }

  Future<DnaSendTransactionResponse> sendTx(String from, String amount,
      String to, String privateKey, String payload) async {
    DnaSendTransactionRequest dnaSendTransactionRequest;
    DnaSendTransactionResponse dnaSendTransactionResponse;

    Map<String, dynamic> mapParams;

    Completer<DnaSendTransactionResponse> _completer =
        new Completer<DnaSendTransactionResponse>();

    try {
      if (this.nodeType == PUBLIC_NODE) {
        if (payload != null && payload.trim().isEmpty == false) {
          String payloadHex = AppHelpers.toHexString(toBuffer(payload), true);
          mapParams = {
            'method': DnaSendTransactionRequest.METHOD_NAME,
            "params": [
              {"from": from, "to": to, 'amount': amount, 'payload': payloadHex}
            ],
            'id': 101
          };
        } else {
          mapParams = {
            'method': DnaSendTransactionRequest.METHOD_NAME,
            "params": [
              {"from": from, "to": to, 'amount': amount}
            ],
            'id': 101
          };
        }
      } else {
        if (payload != null && payload.trim().isEmpty == false) {
          String payloadHex = AppHelpers.toHexString(toBuffer(payload), true);
          mapParams = {
            'method': DnaSendTransactionRequest.METHOD_NAME,
            "params": [
              {"from": from, "to": to, 'amount': amount, 'payload': payloadHex}
            ],
            'id': 101,
            'key': this.keyApp
          };
        } else {
          mapParams = {
            'method': DnaSendTransactionRequest.METHOD_NAME,
            "params": [
              {"from": from, "to": to, 'amount': amount}
            ],
            'id': 101,
            'key': this.keyApp
          };
        }
      }

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaSendTransactionResponse =
              dnaSendTransactionResponseFromJson(response.text);
        } else {
          dnaSendTransactionResponse = new DnaSendTransactionResponse();
          dnaSendTransactionResponse.error =
              new DnaSendTransactionResponseError();
          dnaSendTransactionResponse.error.message = response.text;
        }
      } else {
        if (this.nodeType == SHARED_NODE || this.nodeType == PUBLIC_NODE) {
          int nonce = await getLastNonce(from);
          DnaGetEpochResponse dnaGetEpochResponse = await getDnaGetEpoch();
          int epoch = 0;
          if (dnaGetEpochResponse != null &&
              dnaGetEpochResponse.result != null &&
              dnaGetEpochResponse.result.epoch != null) {
            epoch = dnaGetEpochResponse.result.epoch;
          }

          var amountNumber = BigInt.parse(
              (Decimal.parse(amount) * Decimal.parse("1000000000000000000"))
                  .toString());
          //print('amountNumber: ' + amountNumber.toString());
          var maxFee = 250000000000000000;
          // Create Transaction
          model.Transaction transaction = new model.Transaction(
              nonce + 1, epoch, 0, to, amountNumber, maxFee, null, null);
          //print("transaction.toHex() before sign : " + transaction.toHex());
          transaction.sign(privateKey);
          var rawTxSigned = addHexPrefix(transaction.toHex());
          //print("rawTxSigned : " + rawTxSigned);
          // Sign Raw Tx

          BcnSendRawTxResponse bcnSendRawTxResponse =
              await sendRawTx(rawTxSigned);
          dnaSendTransactionResponse = dnaSendTransactionResponseFromJson(
              bcnSendRawTxResponseToJson(bcnSendRawTxResponse));
        } else {
          dnaSendTransactionRequest =
              DnaSendTransactionRequest.fromJson(mapParams);
          String body = json.encode(dnaSendTransactionRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            dnaSendTransactionResponse =
                dnaSendTransactionResponseFromJson(responseHttp.body);
          } else {
            dnaSendTransactionResponse = new DnaSendTransactionResponse();
            dnaSendTransactionResponse.error =
                new DnaSendTransactionResponseError();
            dnaSendTransactionResponse.error.message = responseHttp.body;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(dnaSendTransactionResponse);
    return _completer.future;
  }

  Future<BcnSyncingResponse> checkSync() async {
    BcnSyncingRequest bcnSyncingRequest;
    BcnSyncingResponse bcnSyncingResponse;

    Map<String, dynamic> mapParams;

    Completer<BcnSyncingResponse> _completer =
        new Completer<BcnSyncingResponse>();

    try {
      if (this.nodeType == DEMO_NODE || this.nodeType == SHARED_NODE) {
        bcnSyncingResponse = new BcnSyncingResponse();
        bcnSyncingResponse.result = new BcnSyncingResponseResult();
        bcnSyncingResponse.result.syncing = DM_SYNC_SYNCING;
        bcnSyncingResponse.result.currentBlock = DM_SYNC_CURRENT_BLOCK;
        bcnSyncingResponse.result.highestBlock = DM_SYNC_HIGHEST_BLOCK;
      } else {
        if (this.nodeType == PUBLIC_NODE) {
          mapParams = {
            'method': BcnSyncingRequest.METHOD_NAME,
            'params': [],
            'id': 101,
          };
        } else {
          mapParams = {
            'method': BcnSyncingRequest.METHOD_NAME,
            'params': [],
            'id': 101,
            'key': this.keyApp
          };
        }

        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            bcnSyncingResponse = bcnSyncingResponseFromJson(response.text);
          }
        } else {
          bcnSyncingRequest = BcnSyncingRequest.fromJson(mapParams);
          String body = json.encode(bcnSyncingRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            bcnSyncingResponse = bcnSyncingResponseFromJson(responseHttp.body);
          }
        }
      }
    } catch (e) {}

    _completer.complete(bcnSyncingResponse);
    return _completer.future;
  }

  double getFeesEstimation() {
    // TODO
    //print("getFeesEstimation: " + fees.toString());
    return 0.25;
  }

  Future<BcnMempoolResponse> getMemPool(String address) async {
    BcnMempoolResponse bcnMempoolResponse;
    BcnMempoolRequest bcnMempoolRequest;

    Map<String, dynamic> mapParams;

    Completer<BcnMempoolResponse> _completer =
        new Completer<BcnMempoolResponse>();

    try {
      mapParams = {
        'method': BcnMempoolRequest.METHOD_NAME,
        "params": [address],
        'id': 101,
        'key': this.keyApp
      };

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          bcnMempoolResponse = bcnMempoolResponseFromJson(response.text);
        }
      } else {
        bcnMempoolRequest = BcnMempoolRequest.fromJson(mapParams);
        String body = json.encode(bcnMempoolRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200 && responseHttp.body != "") {
          bcnMempoolResponse = bcnMempoolResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(bcnMempoolResponse);
    return _completer.future;
  }

  Future<BcnTransactionResponse> getTransaction(
      String hash, String address) async {
    BcnTransactionRequest bcnTransactionRequest;
    BcnTransactionResponse bcnTransactionResponse;

    Map<String, dynamic> mapParams;

    Completer<BcnTransactionResponse> _completer =
        new Completer<BcnTransactionResponse>();

    try {
      if (this.nodeType == PUBLIC_NODE) {
        mapParams = {
          'method': BcnTransactionRequest.METHOD_NAME,
          "params": [hash],
          'id': 101,
        };
      } else {
        mapParams = {
          'method': BcnTransactionRequest.METHOD_NAME,
          "params": [hash],
          'id': 101,
          'key': this.keyApp
        };
      }

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          bcnTransactionResponse =
              bcnTransactionResponseFromJson(response.text);
          if (bcnTransactionResponse != null &&
              bcnTransactionResponse.result != null &&
              bcnTransactionResponse.result.from != address) {
            bcnTransactionResponse = null;
          }
        }
      } else {
        bcnTransactionRequest = BcnTransactionRequest.fromJson(mapParams);
        String body = json.encode(bcnTransactionRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          bcnTransactionResponse =
              bcnTransactionResponseFromJson(responseHttp.body);
          if (bcnTransactionResponse != null &&
              bcnTransactionResponse.result != null &&
              bcnTransactionResponse.result.from != address) {
            bcnTransactionResponse = null;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(bcnTransactionResponse);
    return _completer.future;
  }

  Future<BcnSendRawTxResponse> sendRawTx(String rawTxSigned) async {
    BcnSendRawTxRequest bcnSendRawTxRequest;
    BcnSendRawTxResponse bcnSendRawTxResponse;

    Map<String, dynamic> mapParams;

    Completer<BcnSendRawTxResponse> _completer =
        new Completer<BcnSendRawTxResponse>();

    try {
      if (this.nodeType == PUBLIC_NODE) {
        //print("transaction.toHex : " + rawTxSigned);
        mapParams = {
          'method': BcnSendRawTxRequest.METHOD_NAME,
          "params": [rawTxSigned],
          'id': 101
        };
      } else {
        //print("transaction.toHex : " + rawTxSigned);
        mapParams = {
          'method': BcnSendRawTxRequest.METHOD_NAME,
          "params": [rawTxSigned],
          'id': 101,
          'key': this.keyApp
        };
      }

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          bcnSendRawTxResponse = bcnSendRawTxResponseFromJson(response.text);
        } else {
          bcnSendRawTxResponse = new BcnSendRawTxResponse();
          bcnSendRawTxResponse.error = new BcnSendRawTxResponseError();
          bcnSendRawTxResponse.error.message = response.text;
        }
      } else {
        bcnSendRawTxRequest = BcnSendRawTxRequest.fromJson(mapParams);
        String body = json.encode(bcnSendRawTxRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          bcnSendRawTxResponse =
              bcnSendRawTxResponseFromJson(responseHttp.body);
        } else {
          bcnSendRawTxResponse = new BcnSendRawTxResponse();
          bcnSendRawTxResponse.error = new BcnSendRawTxResponseError();
          bcnSendRawTxResponse.error.message = responseHttp.body;
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(bcnSendRawTxResponse);
    return _completer.future;
  }

  Future<DnaActivateInviteResponse> activateInvitation(
      String key, String address) async {
    DnaActivateInviteRequest dnaActivateInviteRequest;
    DnaActivateInviteResponse dnaActivateInviteResponse;

    Map<String, dynamic> mapParams;

    Completer<DnaActivateInviteResponse> _completer =
        new Completer<DnaActivateInviteResponse>();

    try {
      mapParams = {
        'method': DnaActivateInviteRequest.METHOD_NAME,
        "params": [
          {"key": key, "to": address}
        ],
        'id': 101,
        'key': this.keyApp
      };

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaActivateInviteResponse =
              dnaActivateInviteResponseFromJson(response.text);
        }
      } else {
        dnaActivateInviteRequest = DnaActivateInviteRequest.fromJson(mapParams);
        String body = json.encode(dnaActivateInviteRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          dnaActivateInviteResponse =
              dnaActivateInviteResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(dnaActivateInviteResponse);
    return _completer.future;
  }

  Future<DnaSendInviteResponse> sendInvitation(
      String address, String amount, int nonce, int epoch) async {
    DnaSendInviteRequest dnaSendInviteRequest;
    DnaSendInviteResponse dnaSendInviteResponse;

    Map<String, dynamic> mapParams;

    Completer<DnaSendInviteResponse> _completer =
        new Completer<DnaSendInviteResponse>();

    try {
      mapParams = {
        'method': DnaSendInviteRequest.METHOD_NAME,
        'params': [
          {'to': address, 'amount': amount, 'nonce': nonce, 'epoch': epoch}
        ],
        'id': 101,
        'key': this.keyApp
      };

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaSendInviteResponse = dnaSendInviteResponseFromJson(response.text);
        }
      } else {
        dnaSendInviteRequest = DnaSendInviteRequest.fromJson(mapParams);
        String body = json.encode(dnaSendInviteRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          dnaSendInviteResponse =
              dnaSendInviteResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(dnaSendInviteResponse);
    return _completer.future;
  }

  Future<DeepLinkParamSignin> signin(
      DeepLinkParamSignin deepLinkParam, String privateKey) async {
    DnaSignInResponse dnaSignInResponse;
    DnaSignInRequest dnaSignInRequest;

    Completer<DeepLinkParamSignin> _completer =
        new Completer<DeepLinkParamSignin>();

    Map<String, dynamic> mapParams;

    try {
      if (this.nodeType == PUBLIC_NODE || this.nodeType == SHARED_NODE) {
        deepLinkParam.signature = AppHelpers.toHexString(
            IdenaUrl().getNonceInternal(deepLinkParam.nonce, privateKey), true);
        _completer.complete(deepLinkParam);
        return _completer.future;
      } else {
        mapParams = {
          'method': DnaSignInRequest.METHOD_NAME,
          "params": [deepLinkParam.nonce != null ? deepLinkParam.nonce : ""],
          'id': 101,
          'key': this.keyApp
        };
      }

      if (this.nodeType == NORMAL_VPS_NODE) {
        SSHClientStatus sshClientStatus;
        sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
        if (sshClientStatus.sshClientStatus) {
          sshClient = sshClientStatus.sshClient;
        }
        var response = await ssh.HttpClientImpl(
            clientFactory: () =>
                ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
            this.apiUrl,
            method: 'POST',
            data: jsonEncode(mapParams),
            headers: requestHeaders);
        if (response.status == 200) {
          dnaSignInResponse = dnaSignInResponseFromJson(response.text);
          deepLinkParam.signature = dnaSignInResponse.result;
        }
      } else {
        dnaSignInRequest = DnaSignInRequest.fromJson(mapParams);
        String body = json.encode(dnaSignInRequest.toJson());
        http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          dnaSignInResponse = dnaSignInResponseFromJson(responseHttp.body);
          deepLinkParam.signature = dnaSignInResponse.result;
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }
    //print("signature: " + deepLinkParam.signature);
    _completer.complete(deepLinkParam);
    return _completer.future;
  }

  Future<bool> checkAddressIdena(String address) async {
    bool check = false;
    HttpClient httpClient = new HttpClient();

    Completer<bool> _completer = new Completer<bool>();

    try {
      HttpClientRequest request = await httpClient
          .getUrl(Uri.parse("https://api.idena.io/api/Address/" + address));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        ApiGetAddressResponse apiGetAddressResponse =
            apiGetAddressResponseFromJson(reply);
        if (apiGetAddressResponse != null &&
            apiGetAddressResponse.result != null &&
            apiGetAddressResponse.result.address != null &&
            apiGetAddressResponse.result.address.toUpperCase() ==
                address.toUpperCase()) {
          check = true;
        }
      }
    } catch (e) {
      print("exception : " + e.toString());
    } finally {
      httpClient.close();
    }

    _completer.complete(check);

    return _completer.future;
  }

  Future<int> getFeePerGas() async {
    int feePerGas = 0;
    Completer<int> _completer = new Completer<int>();

    Map<String, dynamic> mapParams;

    try {
      BcnFeePerGasRequest bcnFeePerGasRequest;
      BcnFeePerGasResponse bcnFeePerGasResponse;
      if (this.nodeType == DEMO_NODE) {
        feePerGas = DM_FEE_PER_GAS;
      } else {
        mapParams = {
          'method': BcnFeePerGasRequest.METHOD_NAME,
          'params': [],
          'id': 101,
          'key': this.keyApp
        };

        if (this.nodeType == NORMAL_VPS_NODE) {
          SSHClientStatus sshClientStatus;
          sshClientStatus = await VpsUtil().connectVps(this.apiUrl, keyApp);
          if (sshClientStatus.sshClientStatus) {
            sshClient = sshClientStatus.sshClient;
          }
          var response = await ssh.HttpClientImpl(
              clientFactory: () =>
                  ssh.SSHTunneledBaseClient(sshClientStatus.sshClient)).request(
              this.apiUrl,
              method: 'POST',
              data: jsonEncode(mapParams),
              headers: requestHeaders);
          if (response.status == 200) {
            bcnFeePerGasResponse = bcnFeePerGasResponseFromJson(response.text);

            feePerGas = bcnFeePerGasResponse.result;
          }
        } else {
          bcnFeePerGasRequest = BcnFeePerGasRequest.fromJson(mapParams);
          String body = json.encode(bcnFeePerGasRequest.toJson());
          http.Response responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            bcnFeePerGasResponse =
                bcnFeePerGasResponseFromJson(responseHttp.body);

            feePerGas = bcnFeePerGasResponse.result;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(feePerGas);

    return _completer.future;
  }
}
