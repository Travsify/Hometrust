import 'property_model.dart';
import 'project_model.dart';

class PaymentRecordModel {
  final String id;
  final String paymentReference;
  final double amount;
  final double platformFee;
  final double totalAmount;
  final String purpose;
  final String status;
  final String? receiptNumber;
  final DateTime? paidAt;

  PaymentRecordModel({
    required this.id,
    required this.paymentReference,
    required this.amount,
    required this.platformFee,
    required this.totalAmount,
    required this.purpose,
    required this.status,
    this.receiptNumber,
    this.paidAt,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] ?? '',
      paymentReference: json['paymentReference'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'PENDING',
      receiptNumber: json['receiptNumber'],
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
    );
  }
}

class PurchaseModel {
  final String id;
  final String purchaseCode;
  final String status;
  final double totalPrice;
  final double initialDeposit;
  final double amountPaid;
  final double outstandingBalance;
  final double? nextPaymentAmount;
  final DateTime? nextPaymentDueDate;
  final String? agreementDocumentUrl;
  final PropertyModel? property;
  final ProjectUnitModel? projectUnit;
  final PaymentPlanModel? paymentPlan;
  final DateTime? lockedUntil;
  final String lockStatus;
  final List<PaymentRecordModel> payments;

  PurchaseModel({
    required this.id,
    required this.purchaseCode,
    required this.status,
    required this.totalPrice,
    required this.initialDeposit,
    required this.amountPaid,
    required this.outstandingBalance,
    this.nextPaymentAmount,
    this.nextPaymentDueDate,
    this.agreementDocumentUrl,
    this.property,
    this.projectUnit,
    this.paymentPlan,
    this.lockedUntil,
    this.lockStatus = 'UNLOCKED',
    required this.payments,
  });

  double get progressPercentage => totalPrice > 0 ? (amountPaid / totalPrice).clamp(0.0, 1.0) : 0.0;
  bool get isLockActive => lockStatus == 'LOCKED' && lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
  Duration get lockRemaining => lockedUntil != null ? lockedUntil!.difference(DateTime.now()) : Duration.zero;

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    var pmts = (json['payments'] as List<dynamic>?)
            ?.map((p) => PaymentRecordModel.fromJson(p))
            .toList() ??
        [];

    return PurchaseModel(
      id: json['id'] ?? '',
      purchaseCode: json['purchaseCode'] ?? '',
      status: json['status'] ?? 'INITIATED',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      initialDeposit: (json['initialDeposit'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      nextPaymentAmount: (json['nextPaymentAmount'] as num?)?.toDouble(),
      nextPaymentDueDate: json['nextPaymentDueDate'] != null
          ? DateTime.tryParse(json['nextPaymentDueDate'])
          : null,
      agreementDocumentUrl: json['agreementDocumentUrl'],
      property: json['property'] != null ? PropertyModel.fromJson(json['property']) : null,
      projectUnit: json['projectUnit'] != null ? ProjectUnitModel.fromJson(json['projectUnit']) : null,
      paymentPlan: json['paymentPlan'] != null ? PaymentPlanModel.fromJson(json['paymentPlan']) : null,
      lockedUntil: json['lockedUntil'] != null ? DateTime.tryParse(json['lockedUntil']) : null,
      lockStatus: json['lockStatus'] ?? 'UNLOCKED',
      payments: pmts,
    );
  }
}
