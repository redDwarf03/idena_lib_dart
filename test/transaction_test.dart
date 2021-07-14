library test.transaction_test;

// Package imports:
import 'package:decimal/decimal.dart';
import 'package:idena_lib_dart/model/transaction.dart' as model;
import 'package:test/test.dart';

void main() {
  group('Transaction', () {
    group('signature', () {
      test('should generate a signature', () {
        
        String privateKey = "";
        var amountNumber = BigInt.parse(
            (Decimal.parse("1") * Decimal.parse("1000000000000000000"))
                .toString());
        var maxFee = 250000000000000000;
        model.Transaction transaction = new model.Transaction(
            1, 71, 0, "0x72563cb949bd0167acfff47b5865fe30e1960e70", amountNumber, maxFee, null, null);
        transaction.sign(privateKey);
        expect(transaction.signature,
            '004e89e81096eb09c74a29bdf66e41fc118b6d17ac547223ca6629a71724e69f23');
      });
    });
  });
}
