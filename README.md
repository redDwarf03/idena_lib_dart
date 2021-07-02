# idena_lib_dart

Idena dart library for Flutter based on Official Idena Backoffice

## RPC Methods (from http://rpc.idena.io)

### dna_getBalance
```dart
import 'package:idena_lib_dart/model/response/dna_getBalance_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
DnaGetBalanceResponse dnaGetBalanceResponse = AppService>().getBalanceGetResponse(address);
```

### bcn_transactions
```dart
import 'package:idena_lib_dart/model/response/bcn_transactions_response.dart';
import 'package:idena_lib_dart/factory/app_service.dart';
BcnTransactionsResponse bcnTransactionsResponse = AppService>().getAddressTxsResponse(address, count);
```


## others methods

### get Status
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
String status = AppService>().getWStatusGetResponse();
```

### get Last Nonce
```dart
import 'package:idena_lib_dart/factory/app_service.dart';
int nonce = AppService>().getLastNonce(address);
```






