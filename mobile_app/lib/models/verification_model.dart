class VerificationDocModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final String? aiScanSummary;

  VerificationDocModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.aiScanSummary,
  });

  factory VerificationDocModel.fromJson(Map<String, dynamic> json) {
    return VerificationDocModel(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'],
      aiScanSummary: json['aiScanSummary'],
    );
  }
}

class VerificationCheckModel {
  final String id;
  final String checkName;
  final String category;
  final String status;
  final String? notes;

  VerificationCheckModel({
    required this.id,
    required this.checkName,
    required this.category,
    required this.status,
    this.notes,
  });

  factory VerificationCheckModel.fromJson(Map<String, dynamic> json) {
    return VerificationCheckModel(
      id: json['id'] ?? '',
      checkName: json['checkName'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'],
    );
  }
}

class VerificationRequestModel {
  final String id;
  final String verificationCode;
  final String propertyName;
  final String propertyAddress;
  final String state;
  final String city;
  final String documentType;
  final String status;
  final String urgency;
  final double feeAmount;
  final bool isPaid;
  final String? assignedTo;
  final String? finalFindings;
  final String? reportUrl;
  final String deliveryOption;
  final String? deliveryAddress;
  final double deliveryFee;
  final String deliveryStatus;
  final String? courierPartner;
  final String? waybillNumber;
  final String? deliveryOtp;
  final List<VerificationDocModel> documents;
  final List<VerificationCheckModel> checks;

  VerificationRequestModel({
    required this.id,
    required this.verificationCode,
    required this.propertyName,
    required this.propertyAddress,
    required this.state,
    required this.city,
    required this.documentType,
    required this.status,
    required this.urgency,
    required this.feeAmount,
    required this.isPaid,
    this.assignedTo,
    this.finalFindings,
    this.reportUrl,
    this.deliveryOption = 'DIGITAL_ONLY',
    this.deliveryAddress,
    this.deliveryFee = 0.0,
    this.deliveryStatus = 'PENDING',
    this.courierPartner,
    this.waybillNumber,
    this.deliveryOtp,
    required this.documents,
    required this.checks,
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    var docs = (json['documents'] as List<dynamic>?)
            ?.map((d) => VerificationDocModel.fromJson(d))
            .toList() ??
        [];

    var chks = (json['checks'] as List<dynamic>?)
            ?.map((c) => VerificationCheckModel.fromJson(c))
            .toList() ??
        [];

    return VerificationRequestModel(
      id: json['id'] ?? '',
      verificationCode: json['verificationCode'] ?? '',
      propertyName: json['propertyName'] ?? '',
      propertyAddress: json['propertyAddress'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      documentType: json['documentType'] ?? 'C_OF_O',
      status: json['status'] ?? 'SUBMITTED',
      urgency: json['urgency'] ?? 'STANDARD',
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 25000.0,
      isPaid: json['isPaid'] ?? false,
      assignedTo: json['assignedTo'],
      finalFindings: json['finalFindings'],
      reportUrl: json['reportUrl'],
      deliveryOption: json['deliveryOption'] ?? 'DIGITAL_ONLY',
      deliveryAddress: json['deliveryAddress'],
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      deliveryStatus: json['deliveryStatus'] ?? 'PENDING',
      courierPartner: json['courierPartner'],
      waybillNumber: json['waybillNumber'],
      deliveryOtp: json['deliveryOtp'],
      documents: docs,
      checks: chks,
    );
  }
}
