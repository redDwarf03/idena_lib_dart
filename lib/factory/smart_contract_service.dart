// @dart=2.9

// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:decimal/decimal.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:web3dart/crypto.dart' as crypto show keccak256;

// Project imports:
import 'package:idena_lib_dart/factory/app_service.dart';
import 'package:idena_lib_dart/model/deployContractAttachment.dart';
import 'package:idena_lib_dart/model/node_type.dart';
import 'package:idena_lib_dart/model/request/bcn_tx_receipt_request.dart';
import 'package:idena_lib_dart/model/request/contract/api_contract_balance_updates_response.dart';
import 'package:idena_lib_dart/model/request/contract/api_contract_response.dart';
import 'package:idena_lib_dart/model/request/contract/api_contract_txs_response.dart';
import 'package:idena_lib_dart/model/request/contract/contract_call_multisig_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_call_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_call_time_lock_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_deploy_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_estimate_deploy_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_get_stake_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_iterate_map_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_read_data_request.dart';
import 'package:idena_lib_dart/model/request/contract/contract_terminate_request.dart';
import 'package:idena_lib_dart/model/response/bcn_transactions_response.dart';
import 'package:idena_lib_dart/model/response/bcn_tx_receipt_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_call_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_deploy_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_estimate_deploy_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_get_stake_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_iterate_map_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_read_data_byte_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_read_data_hex_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_read_data_uint64_response.dart';
import 'package:idena_lib_dart/model/response/contract/contract_terminate_response.dart';
import 'package:idena_lib_dart/model/response/dna_getEpoch_response.dart';
import 'package:idena_lib_dart/pubdev/dartssh/client.dart';
import 'package:idena_lib_dart/pubdev/dartssh/http.dart' as ssh;
import 'package:idena_lib_dart/pubdev/ethereum_util/bytes.dart';
import 'package:idena_lib_dart/pubdev/ethereum_util/utils.dart';
import 'package:idena_lib_dart/util/helpers.dart';
import 'package:idena_lib_dart/util/util_vps.dart';

class SmartContractService {
  var logger = Logger();
  final Map<String, String> requestHeaders = {
    'Content-type': 'application/json',
  };

  SmartContractService({this.nodeType, this.apiUrl, this.keyApp});

  int nodeType;
  String apiUrl;
  String keyApp;

  String body;
  http.Response responseHttp;

  SSHClient sshClient;

  Future<BcnTxReceiptResponse> getTxReceipt(String txHash) async {
    BcnTxReceiptRequest bcnTxReceiptRequest;
    BcnTxReceiptResponse bcnTxReceiptResponse;

    Map<String, dynamic> mapParams;

    Completer<BcnTxReceiptResponse> _completer =
        new Completer<BcnTxReceiptResponse>();

    if (this.nodeType == PUBLIC_NODE) {
      mapParams = {
        'method': BcnTxReceiptRequest.METHOD_NAME,
        'params': [txHash],
        'id': 101,
      };
    } else {
      mapParams = {
        'method': BcnTxReceiptRequest.METHOD_NAME,
        'params': [txHash],
        'id': 101,
        'key': keyApp
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
          bcnTxReceiptResponse = bcnTxReceiptResponseFromJson(response.text);
        }
      } else {
        bcnTxReceiptRequest = BcnTxReceiptRequest.fromJson(mapParams);
        body = json.encode(bcnTxReceiptRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          bcnTxReceiptResponse =
              bcnTxReceiptResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(bcnTxReceiptResponse);

    return _completer.future;
  }

  Future<String> getPredictSmartContractAddress(String address) async {
    var addr = toBuffer(address);
    var epoch;
    DnaGetEpochResponse dnaGetEpochResponse =
        await AppService().getDnaGetEpoch();
    if (dnaGetEpochResponse != null && dnaGetEpochResponse.result != null) {
      epoch = intToBuffer(dnaGetEpochResponse.result.epoch);
    }
    var nonce = intToBuffer(await AppService().getLastNonce(address) + 1);
    var res = Uint8List.fromList([
      ...addr,
      ...epoch,
      ...Uint8List(2 - epoch.length),
      ...nonce,
      ...Uint8List(4 - nonce.length)
    ]);
    var hash = crypto.keccak256(res);
    String addressSC =
        AppHelpers.toHexString(hash.sublist(hash.length - 20), true);
    //print('addressSC: ' + addressSC);
    return addressSC;
  }

  Future<ContractDeployResponse> contractDeployTimeLock(
      String nodeAddress, int timestamp, double amount, double maxFee) async {
    ContractDeployRequest contractDeployRequest;
    ContractDeployResponse contractDeployResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractDeployResponse> _completer =
        new Completer<ContractDeployResponse>();

    mapParams = {
      'method': ContractDeployRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "codeHash": "0x01",
          "amount": amount,
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "uint64", "value": timestamp.toString()}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractDeployResponse =
              contractDeployResponseFromJson(response.text);
        }
      } else {
        if (this.nodeType == SHARED_NODE) {
          contractDeployRequest = ContractDeployRequest.fromJson(mapParams);

          AppService().sendTx(
              nodeAddress,
              amount.toString(),
              "",
              "",
              HEX.encode(new DeployContractAttachment(
                      "0x01", contractDeployRequest.params.last.args)
                  .toBytes()));
        } else {
          contractDeployRequest = ContractDeployRequest.fromJson(mapParams);
          body = json.encode(contractDeployRequest.toJson());
          responseHttp = await http.post(Uri.parse(this.apiUrl),
              body: body, headers: requestHeaders);
          if (responseHttp.statusCode == 200) {
            contractDeployResponse =
                contractDeployResponseFromJson(responseHttp.body);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
      contractDeployResponse = new ContractDeployResponse();
      contractDeployResponse.error = new ContractDeployResponseError();
      contractDeployResponse.error.message = e.toString();
    }

    _completer.complete(contractDeployResponse);

    return _completer.future;
  }

  Future<ContractDeployResponse> contractDeployMultiSig(String nodeAddress,
      int maxVotes, int minVotes, double amount, double maxFee) async {
    ContractDeployRequest contractDeployRequest;
    ContractDeployResponse contractDeployResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractDeployResponse> _completer =
        new Completer<ContractDeployResponse>();

    mapParams = {
      'method': ContractDeployRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "codeHash": "0x05",
          "amount": amount,
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "byte", "value": maxVotes.toString()},
            {"index": 1, "format": "byte", "value": minVotes.toString()}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractDeployResponse =
              contractDeployResponseFromJson(response.text);
        }
      } else {
        contractDeployRequest = ContractDeployRequest.fromJson(mapParams);
        body = json.encode(contractDeployRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractDeployResponse =
              contractDeployResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
      contractDeployResponse = new ContractDeployResponse();
      contractDeployResponse.error = new ContractDeployResponseError();
      contractDeployResponse.error.message = e.toString();
    }

    _completer.complete(contractDeployResponse);

    return _completer.future;
  }

  Future<ContractEstimateDeployResponse> contractEstimateDeployTimeLock(
      String nodeAddress, int timestamp, double amount) async {
    ContractEstimateDeployRequest contractEstimateDeployRequest;
    ContractEstimateDeployResponse contractEstimateDeployResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractEstimateDeployResponse> _completer =
        new Completer<ContractEstimateDeployResponse>();

    mapParams = {
      'method': ContractEstimateDeployRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "codeHash": "0x01",
          "amount": amount,
          "args": [
            {"index": 0, "format": "uint64", "value": timestamp.toString()}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractEstimateDeployResponse =
              contractEstimateDeployResponseFromJson(response.text);
        }
      } else {
        contractEstimateDeployRequest =
            ContractEstimateDeployRequest.fromJson(mapParams);
        body = json.encode(contractEstimateDeployRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractEstimateDeployResponse =
              contractEstimateDeployResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractEstimateDeployResponse);

    return _completer.future;
  }

  Future<ContractEstimateDeployResponse> contractEstimateDeployMultiSig(
      String nodeAddress, int maxVotes, int minVotes, double amount) async {
    ContractEstimateDeployRequest contractEstimateDeployRequest;
    ContractEstimateDeployResponse contractEstimateDeployResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractEstimateDeployResponse> _completer =
        new Completer<ContractEstimateDeployResponse>();

    mapParams = {
      'method': ContractEstimateDeployRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "codeHash": "0x05",
          "amount": amount,
          "args": [
            {"index": 0, "format": "byte", "value": maxVotes.toString()},
            {"index": 1, "format": "byte", "value": minVotes.toString()}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractEstimateDeployResponse =
              contractEstimateDeployResponseFromJson(response.text);
        }
      } else {
        contractEstimateDeployRequest =
            ContractEstimateDeployRequest.fromJson(mapParams);
        body = json.encode(contractEstimateDeployRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractEstimateDeployResponse =
              contractEstimateDeployResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractEstimateDeployResponse);

    return _completer.future;
  }

  Future<ContractCallResponse> contractCallTransferTimeLock(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress,
      String amount) async {
    ContractCallTimeLockRequest contractCallRequest;
    ContractCallResponse contractCallResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractCallResponse> _completer =
        new Completer<ContractCallResponse>();

    mapParams = {
      'method': ContractCallRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "method": "transfer",
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress},
            {"index": 1, "format": "dna", "value": amount}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractCallResponse = contractCallResponseFromJson(response.text);
        }
      } else {
        contractCallRequest = ContractCallTimeLockRequest.fromJson(mapParams);
        body = json.encode(contractCallRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractCallResponse =
              contractCallResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractCallResponse);

    return _completer.future;
  }

  Future<ContractCallResponse> contractCallSendMultiSig(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress,
      String amount) async {
    ContractCallMultiSigRequest contractCallRequest;
    ContractCallResponse contractCallResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractCallResponse> _completer =
        new Completer<ContractCallResponse>();

    mapParams = {
      'method': ContractCallRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "method": "send",
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress},
            {"index": 1, "format": "dna", "value": amount}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractCallResponse = contractCallResponseFromJson(response.text);
        }
      } else {
        contractCallRequest = ContractCallMultiSigRequest.fromJson(mapParams);
        body = json.encode(contractCallRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractCallResponse =
              contractCallResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractCallResponse);

    return _completer.future;
  }

  Future<String> getMultiSigToSend(String address) async {
    if (address == null) return null;

    BcnTransactionsResponse bcnTransactionsResponse =
        await AppService().getAddressTxsResponse(address, 100);
    if (bcnTransactionsResponse != null &&
        bcnTransactionsResponse.result != null &&
        bcnTransactionsResponse.result.transactions != null) {
      for (int i = 0;
          i < bcnTransactionsResponse.result.transactions.length;
          i++) {
        if (bcnTransactionsResponse.result.transactions[i].payload != null &&
            bcnTransactionsResponse.result.transactions[i].payload
                .trim()
                .isNotEmpty) {
          try {
            String payloadFromHex = AppHelpers.fromHexString(
                bcnTransactionsResponse.result.transactions[i].payload);
            if (payloadFromHex.contains("multisig:")) {
              return payloadFromHex.split(":")[1];
            }
          } catch (e) {}
        }
      }
    }
    return null;
  }

  Future<ContractCallResponse> contractCallAddMultiSig(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress,
      String privateKey) async {
    ContractCallMultiSigRequest contractCallRequest;
    ContractCallResponse contractCallResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractCallResponse> _completer =
        new Completer<ContractCallResponse>();

    mapParams = {
      'method': ContractCallRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "method": "add",
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress},
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractCallResponse = contractCallResponseFromJson(response.text);

          if (contractCallResponse != null &&
              contractCallResponse.result != null) {
            AppService().sendTx(nodeAddress, "0", destinationAddress,
                privateKey, "multisig:" + contract);
          }
        }
      } else {
        contractCallRequest = ContractCallMultiSigRequest.fromJson(mapParams);
        body = json.encode(contractCallRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractCallResponse =
              contractCallResponseFromJson(responseHttp.body);

          if (contractCallResponse != null &&
              contractCallResponse.result != null) {
            AppService().sendTx(nodeAddress, "0", destinationAddress,
                privateKey, "multisig:" + contract);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractCallResponse);

    return _completer.future;
  }

  Future<ContractCallResponse> contractCallPushMultiSig(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress,
      String amount) async {
    ContractCallTimeLockRequest contractCallRequest;
    ContractCallResponse contractCallResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractCallResponse> _completer =
        new Completer<ContractCallResponse>();

    mapParams = {
      'method': ContractCallRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "method": "push",
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress},
            {"index": 1, "format": "dna", "value": amount}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractCallResponse = contractCallResponseFromJson(response.text);
        }
      } else {
        contractCallRequest = ContractCallTimeLockRequest.fromJson(mapParams);
        body = json.encode(contractCallRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractCallResponse =
              contractCallResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractCallResponse);

    return _completer.future;
  }

  Future<ContractTerminateResponse> contractTerminateTimeLock(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress) async {
    ContractTerminateRequest contractTerminateRequest;
    ContractTerminateResponse contractTerminateResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractTerminateResponse> _completer =
        new Completer<ContractTerminateResponse>();

    mapParams = {
      'method': ContractTerminateRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractTerminateResponse =
              contractTerminateResponseFromJson(response.text);
        }
      } else {
        contractTerminateRequest = ContractTerminateRequest.fromJson(mapParams);
        body = json.encode(contractTerminateRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractTerminateResponse =
              contractTerminateResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractTerminateResponse);

    return _completer.future;
  }

  Future<ContractTerminateResponse> contractTerminateMultiSig(
      String nodeAddress,
      String contract,
      double maxFee,
      String destinationAddress) async {
    ContractTerminateRequest contractTerminateRequest;
    ContractTerminateResponse contractTerminateResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractTerminateResponse> _completer =
        new Completer<ContractTerminateResponse>();

    mapParams = {
      'method': ContractTerminateRequest.METHOD_NAME,
      'params': [
        {
          "from": nodeAddress,
          "contract": contract,
          "maxFee": maxFee,
          "args": [
            {"index": 0, "format": "hex", "value": destinationAddress}
          ]
        }
      ],
      'id': 101,
      'key': keyApp
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
          contractTerminateResponse =
              contractTerminateResponseFromJson(response.text);
        }
      } else {
        contractTerminateRequest = ContractTerminateRequest.fromJson(mapParams);
        body = json.encode(contractTerminateRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractTerminateResponse =
              contractTerminateResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractTerminateResponse);

    return _completer.future;
  }

  Future<ApiContractResponse> getContract(String contractAddress) async {
    HttpClient httpClient = new HttpClient();
    ApiContractResponse apiContractResponse;
    Completer<ApiContractResponse> _completer =
        new Completer<ApiContractResponse>();

    try {
      HttpClientRequest request = await httpClient.getUrl(
          Uri.parse("https://api.idena.io/api/Contract/" + contractAddress));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        apiContractResponse = apiContractResponseFromJson(reply);
      }
    } catch (e) {
      print("exception : " + e.toString());
    } finally {
      httpClient.close();
    }

    _completer.complete(apiContractResponse);

    return _completer.future;
  }

  Future<ApiContractBalanceUpdatesResponse> getContractBalanceUpdates(
      String address, String contractAddress, int limit) async {
    HttpClient httpClient = new HttpClient();
    ApiContractBalanceUpdatesResponse apiContractBalanceUpdatesResponse;
    Completer<ApiContractBalanceUpdatesResponse> _completer =
        new Completer<ApiContractBalanceUpdatesResponse>();

    String uri;
    if (address != null) {
      uri = "https://api.idena.io/api/Address/" +
          address +
          "/Contract/" +
          contractAddress +
          "/BalanceUpdates?limit=" +
          limit.toString();
    } else {
      uri = "https://api.idena.io/api/Contract/" +
          contractAddress +
          "/BalanceUpdates?limit=" +
          limit.toString();
    }

    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(uri));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        apiContractBalanceUpdatesResponse =
            apiContractBalanceUpdatesResponseFromJson(reply);
      }
    } catch (e) {
      print("exception : " + e.toString());
    } finally {
      httpClient.close();
    }

    _completer.complete(apiContractBalanceUpdatesResponse);

    return _completer.future;
  }

  Future<ApiContractTxsResponse> getContractTxs(
      String address, int limit, String typeOfContract) async {
    HttpClient httpClient = new HttpClient();
    ApiContractTxsResponse apiContractTxsResponse =
        new ApiContractTxsResponse();
    apiContractTxsResponse.result =
        List<ApiContractTxsResponseResult>.empty(growable: true);
    Completer<ApiContractTxsResponse> _completer =
        new Completer<ApiContractTxsResponse>();

    Map contractCharged = new Map();

    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          "https://api.idena.io/api/Address/" +
              address +
              "/Txs?limit=" +
              limit.toString()));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        ApiContractTxsResponse apiContractTxsResponseTmp =
            apiContractTxsResponseFromJson(reply);
        if (apiContractTxsResponseTmp != null &&
            apiContractTxsResponseTmp.result != null) {
          for (int i = 0; i < apiContractTxsResponseTmp.result.length; i++) {
            if (apiContractTxsResponseTmp.result[i].type == "CallContract" ||
                apiContractTxsResponseTmp.result[i].type ==
                    "TerminateContract" ||
                apiContractTxsResponseTmp.result[i].type == "DeployContract") {
              String contractAddress = apiContractTxsResponseTmp.result[i].to;
              if (apiContractTxsResponseTmp.result[i].type ==
                  "DeployContract") {
                BcnTxReceiptResponse bcnTxReceiptResponse = await getTxReceipt(
                    apiContractTxsResponseTmp.result[i].hash);
                if (bcnTxReceiptResponse != null &&
                    bcnTxReceiptResponse.result != null) {
                  contractAddress = bcnTxReceiptResponse.result.contract;
                  apiContractTxsResponseTmp.result[i].to = contractAddress;
                }
              }

              if (contractAddress != null &&
                  contractCharged.containsKey(contractAddress.toUpperCase()) ==
                      false) {
                ApiContractResponse apiContractResponse =
                    await getContract(contractAddress);
                if (apiContractResponse != null &&
                    apiContractResponse.result != null &&
                    apiContractResponse.result.type == typeOfContract) {
                  apiContractTxsResponse.result
                      .add(apiContractTxsResponseTmp.result[i]);
                  contractCharged.putIfAbsent(contractAddress.toUpperCase(),
                      () => contractAddress.toUpperCase());
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("exception : " + e.toString());
    } finally {
      httpClient.close();
    }

    _completer.complete(apiContractTxsResponse);

    return _completer.future;
  }

  Future<int> getContractReadDataUint64(
      String contractAddress, String key) async {
    ContractReadDataRequest contractReadDataRequest;
    ContractReadDataUint64Response contractReadDataResponse;

    Map<String, dynamic> mapParams;

    Completer<int> _completer = new Completer<int>();

    mapParams = {
      'method': ContractReadDataRequest.METHOD_NAME,
      'params': [contractAddress, key, "uint64"],
      'id': 101,
      'key': keyApp
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
          contractReadDataResponse =
              contractReadDataUint64ResponseFromJson(response.text);
        }
      } else {
        contractReadDataRequest = ContractReadDataRequest.fromJson(mapParams);
        body = json.encode(contractReadDataRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractReadDataResponse =
              contractReadDataUint64ResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    if (contractReadDataResponse != null) {
      _completer.complete(contractReadDataResponse.result);
    } else {
      _completer.complete(0);
    }

    return _completer.future;
  }

  Future<String> getContractReadDataHex(
      String contractAddress, String key) async {
    ContractReadDataRequest contractReadDataRequest;
    ContractReadDataHexResponse contractReadDataResponse;

    Map<String, dynamic> mapParams;

    Completer<String> _completer = new Completer<String>();

    mapParams = {
      'method': ContractReadDataRequest.METHOD_NAME,
      'params': [contractAddress, key, "hex"],
      'id': 101,
      'key': keyApp
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
          contractReadDataResponse =
              contractReadDataHexResponseFromJson(response.text);
        }
      } else {
        contractReadDataRequest = ContractReadDataRequest.fromJson(mapParams);
        body = json.encode(contractReadDataRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractReadDataResponse =
              contractReadDataHexResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    if (contractReadDataResponse != null) {
      _completer.complete(contractReadDataResponse.result);
    } else {
      _completer.complete("");
    }

    return _completer.future;
  }

  Future<int> getContractReadDataByte(
      String contractAddress, String key) async {
    ContractReadDataRequest contractReadDataRequest;
    ContractReadDataByteResponse contractReadDataResponse;

    Map<String, dynamic> mapParams;

    Completer<int> _completer = new Completer<int>();

    mapParams = {
      'method': ContractReadDataRequest.METHOD_NAME,
      'params': [contractAddress, key, "byte"],
      'id': 101,
      'key': keyApp
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
          contractReadDataResponse =
              contractReadDataByteResponseFromJson(response.text);
        }
      } else {
        contractReadDataRequest = ContractReadDataRequest.fromJson(mapParams);
        body = json.encode(contractReadDataRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractReadDataResponse =
              contractReadDataByteResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    if (contractReadDataResponse != null) {
      _completer.complete(contractReadDataResponse.result);
    } else {
      _completer.complete(0);
    }

    return _completer.future;
  }

  Future<ContractGetStakeResponse> getContractStake(
      String contractAddress) async {
    ContractGetStakeRequest contractGetStakeRequest;
    ContractGetStakeResponse contractGetStakeResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractGetStakeResponse> _completer =
        new Completer<ContractGetStakeResponse>();

    mapParams = {
      'method': ContractGetStakeRequest.METHOD_NAME,
      'params': [
        contractAddress,
      ],
      'id': 101,
      'key': keyApp
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
          contractGetStakeResponse =
              contractGetStakeResponseFromJson(response.text);
        }
      } else {
        contractGetStakeRequest = ContractGetStakeRequest.fromJson(mapParams);
        body = json.encode(contractGetStakeRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractGetStakeResponse =
              contractGetStakeResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractGetStakeResponse);

    return _completer.future;
  }

  Future<double> getSmartContractStake() async {
    int feePerGas = await AppService().getFeePerGas();
    double smartContractStake = double.parse(
        (Decimal.parse(feePerGas.toString()) /
                Decimal.parse("1000000000000000000") *
                Decimal.parse("3000000"))
            .toString());
    //print("smartContractStake: " + smartContractStake.toString());
    return smartContractStake;
  }

  Future<ContractIterateMapResponse> getContractIterateMapAmount(
      String contractAddress, String continuationToken) {
    return getContractIterateMap(
        contractAddress, "amount", continuationToken, "hex", "hex", 32);
  }

  Future<ContractIterateMapResponse> getContractIterateMapAddr(
      String contractAddress, String continuationToken) {
    return getContractIterateMap(
        contractAddress, "addr", continuationToken, "hex", "hex", 32);
  }

  Future<ContractIterateMapResponse> getContractIterateMap(
      String contractAddress,
      String map,
      String continuationToken,
      String keyFormat,
      String valueFormat,
      int limit) async {
    ContractIterateMapRequest contractIterateMapRequest;
    ContractIterateMapResponse contractIterateMapResponse;

    Map<String, dynamic> mapParams;

    Completer<ContractIterateMapResponse> _completer =
        new Completer<ContractIterateMapResponse>();

    mapParams = {
      'method': ContractIterateMapRequest.METHOD_NAME,
      'params': [
        contractAddress,
        map,
        continuationToken,
        keyFormat,
        valueFormat,
        limit
      ],
      'id': 101,
      'key': keyApp
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
          contractIterateMapResponse =
              contractIterateMapResponseFromJson(response.text);
        }
      } else {
        contractIterateMapRequest =
            ContractIterateMapRequest.fromJson(mapParams);
        body = json.encode(contractIterateMapRequest.toJson());
        responseHttp = await http.post(Uri.parse(this.apiUrl),
            body: body, headers: requestHeaders);
        if (responseHttp.statusCode == 200) {
          contractIterateMapResponse =
              contractIterateMapResponseFromJson(responseHttp.body);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    _completer.complete(contractIterateMapResponse);

    return _completer.future;
  }
}
