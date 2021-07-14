# idena_lib_dart

Idena dart library for Flutter based on Official Idena Backoffice

## RPC Methods (from http://rpc.idena.io)

### dna_getBalance
```dart
import 'package:idena_lib_dart/model/response/dna_getBalance_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaGetBalanceResponse dnaGetBalanceResponse = AppService().getBalanceGetResponse(address);
```

### bcn_transactions
```dart
import 'package:idena_lib_dart/model/response/bcn_transactions_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnTransactionsResponse bcnTransactionsResponse = AppService().getAddressTxsResponse(address, count);
```

### dna_getCoinbaseAddr
```dart
import 'package:idena_lib_dart/model/response/dna_getCoinbaseAddr_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaGetCoinbaseAddrResponse dnaGetCoinbaseAddrResponse = AppService().getDnaGetCoinbaseAddr(addressByDefault);
```

### dna_identity
```dart
import 'package:idena_lib_dart/model/response/dna_identity_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaIdentityResponse dnaIdentityResponse = AppService().getDnaIdentity(address);
```

### dna_epoch
```dart
import 'package:idena_lib_dart/model/response/dna_getEpoch_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaGetEpochResponse dnaGetEpochResponse = AppService().getDnaGetEpoch();
```

### dna_ceremonyIntervals
```dart
import 'package:idena_lib_dart/model/response/dna_ceremonyIntervals_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaCeremonyIntervalsResponse dnaCeremonyIntervalsResponse = AppService().getDnaCeremonyIntervals();
```

### dna_becomeOnline
```dart
import 'package:idena_lib_dart/model/response/dna_becomeOnline_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaBecomeOnlineResponse dnaBecomeOnlineResponse = AppService().becomeOnline();
```

### dna_becomeOffline
```dart
import 'package:idena_lib_dart/model/response/dna_becomeOffline_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaBecomeOfflineResponse dnaBecomeOfflineResponse = AppService().becomeOffline();
```

### dna_sendTransaction
```dart
import 'package:idena_lib_dart/model/response/dna_sendTransaction_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaSendTransactionResponse dnaSendTransactionResponse = AppService().sendTx(from, amount, to, privateKey, payload);
```

### bcn_syncing
```dart
import 'package:idena_lib_dart/model/response/bcn_syncing_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnSyncingResponse bcnSyncingResponse = AppService().checkSync();
```

### bcn_mempool
```dart
import 'package:idena_lib_dart/model/response/bcn_mempool_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnMempoolResponse bcnMempoolResponse = AppService().getMemPool(address);
```

### bcn_transaction
```dart
import 'package:idena_lib_dart/model/response/bcn_transaction_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnTransactionResponse bcnTransactionResponse = AppService().getTransaction(hash, address);
```

### bcn_sendRawTx
```dart
import 'package:idena_lib_dart/model/response/bcn_send_raw_tx_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnSendRawTxResponse bcnSendRawTxResponse = AppService().sendRawTx(hash, address);
```

### dna_activateInvite
```dart
import 'package:idena_lib_dart/model/response/dna_activate_invite_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaActivateInviteResponse dnaActivateInviteResponse = AppService().activateInvitation(key, address);
```

### dna_sendInvite
```dart
import 'package:idena_lib_dart/model/response/dna_send_invite_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaSendInviteResponse dnaSendInviteResponse = AppService().sendInvitation(address, amount, nonce, epoch);
```

### dna_sign
```dart
import 'package:idena_lib_dart/deepLinks/deepLinkParamSignin.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DeepLinkParamSignin deepLinkParam = AppService().signin(deepLinkParam, privateKey);
```

### bcn_feePerGas
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
int feePerGas = AppService().getFeePerGas();
```

### bcn_txReceipt
```dart
import 'package:idena_lib_dart/model/response/contract/bcn_tx_receipt_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
BcnTxReceiptResponse bcnTxReceiptResponse = SmartContractService().getTxReceipt(txHash);
```

### contract_deploy (TimeLock)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_deploy_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractDeployResponse contractDeployResponse = SmartContractService().contractDeployTimeLock(nodeAddress, timestamp, amount, maxFee);
```

### contract_deploy (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_deploy_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractDeployResponse contractDeployResponse = SmartContractService().contractDeployMultiSig(nodeAddress, maxVotes, minVotes, amount, maxFee);
```

### contract_estimateDeploy (TimeLock)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_estimate_deploy_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractEstimateDeployResponse contractEstimateDeployResponse = SmartContractService().contractEstimateDeployTimeLock(nodeAddress, timestamp, amount);
```

### contract_estimateDeploy (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_estimate_deploy_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractEstimateDeployResponse contractEstimateDeployResponse = SmartContractService().contractEstimateDeployMultiSig(nodeAddress, maxVotes, minVotes, amount);
```

### contract_call - method Transfer (TimeLock)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_call_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractCallResponse contractCallResponse = SmartContractService().contractCallTransferTimeLock(nodeAddress, contract, maxFee, destinationAddress, amount);
```

### contract_call - method Send (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_call_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractCallResponse contractCallResponse = SmartContractService().contractCallSendMultiSig(nodeAddress, contract, maxFee, destinationAddress, amount);
```

### contract_call - method Add (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_call_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractCallResponse contractCallResponse = SmartContractService().contractCallAddMultiSig(nodeAddress, contract, maxFee, destinationAddress, privateKey);
```

### contract_call - method Push (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_call_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractCallResponse contractCallResponse = SmartContractService().contractCallPushMultiSig(nodeAddress, contract, maxFee, destinationAddress, amount);
```

### contract_terminate (TimeLock)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_terminate_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractTerminateResponse contractTerminateResponse = SmartContractService().contractTerminateTimeLock(nodeAddress, contract, maxFee, destinationAddress);
```

### contract_terminate (MultiSig)
```dart
import 'package:idena_lib_dart/model/response/contract/contract_terminate_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractTerminateResponse contractTerminateResponse = SmartContractService().contractTerminateMultiSig(nodeAddress, contract, maxFee, destinationAddress);
```

### contract_readData (uint64)
```dart
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
int value = SmartContractService().getContractReadDataUint64(contractAddress, key);
```

### contract_readData (hex)
```dart
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
String value = SmartContractService().getContractReadDataHex(contractAddress, key);
```

### contract_readData (byte)
```dart
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
int byte = SmartContractService().getContractReadDataHex(contractAddress, key);
```

### contract_getStake
```dart
import 'package:idena_lib_dart/model/response/contract_get_stake_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ContractGetStakeResponse contractGetStakeResponse = SmartContractService().getContractStake(contractAddress);
```


## others methods

### get Status
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
String status = AppService().getWStatusGetResponse();
```

### get Last Nonce
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
int nonce = AppService().getLastNonce(address);
```

### get Current Period
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
String currentPeriod = AppService().getCurrentPeriod();
```

### check Address
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
bool isIdenaAddress = AppService().checkAddressIdena(address);
```

### get Predict Smart Contract Address
```dart
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
String address = SmartContractService().getPredictSmartContractAddress(address);
```

### get Smart Contract
```dart
import 'package:idena_lib_dart/model/response/contract/api_contract_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ApiContractResponse apiContractResponse = SmartContractService().getContract(contractAddress);
```

### get Smart Contract Balance Updates
```dart
import 'package:idena_lib_dart/model/response/api_contract_balance_updates_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ApiContractBalanceUpdatesResponse apiContractBalanceUpdatesResponse = SmartContractService().getContractBalanceUpdates(address, contractAddress, limit);
```

### get Smart Contract Transactions
```dart
import 'package:idena_lib_dart/model/response/api_contract_txs_response.dart';
import 'package:idena_lib_dart/factory/smart_contract_service.dart';
ApiContractTxsResponse apiContractTxsResponse = SmartContractService().getContractTxs(address, address, limit, typeOfContract);
```

