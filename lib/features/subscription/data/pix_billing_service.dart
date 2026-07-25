import 'package:cloud_functions/cloud_functions.dart';

/// Resposta da callable `createPixAnnualPayment`.
final class PixCharge {
  const PixCharge({
    required this.paymentId,
    required this.amount,
    required this.copyPaste,
    this.encodedImage,
    this.expirationDate,
  });

  final String paymentId;
  final double amount;
  final String copyPaste;
  final String? encodedImage;
  final String? expirationDate;

  factory PixCharge.fromMap(Map<String, dynamic> map) {
    final copy = map['copyPaste'] as String? ?? '';
    final id = map['paymentId'] as String? ?? '';
    if (id.isEmpty || copy.isEmpty) {
      throw StateError('Resposta PIX incompleta do backend.');
    }
    final amountRaw = map['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : 118.80;
    return PixCharge(
      paymentId: id,
      amount: amount,
      copyPaste: copy,
      encodedImage: map['encodedImage'] as String?,
      expirationDate: map['expirationDate'] as String?,
    );
  }
}

class PixBillingService {
  PixBillingService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  Future<PixCharge> createAnnualPixPayment() async {
    final callable = _functions.httpsCallable('createPixAnnualPayment');
    final result = await callable.call();
    final raw = result.data;
    if (raw is! Map) {
      throw StateError('Resposta inválida do backend.');
    }
    return PixCharge.fromMap(Map<String, dynamic>.from(raw));
  }
}
