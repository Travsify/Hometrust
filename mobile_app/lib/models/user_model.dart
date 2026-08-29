class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isVerified;
  final String? nin;
  final String? virtualAccountNumber;
  final String? virtualBankName;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.isVerified = false,
    this.nin,
    this.virtualAccountNumber,
    this.virtualBankName,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final developer = json['developer'] as Map<String, dynamic>?;
    final virtualAccounts = json['virtualAccounts'] as List<dynamic>?;
    final firstAccount = virtualAccounts != null && virtualAccounts.isNotEmpty
        ? virtualAccounts[0] as Map<String, dynamic>?
        : null;

    final bool verified = (profile != null && profile['nin'] != null) ||
        (developer != null && (developer['isVerified'] == true || developer['verificationStatus'] == 'VERIFIED')) ||
        json['isVerified'] == true;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'BUYER',
      avatarUrl: json['avatarUrl'],
      isVerified: verified,
      nin: profile?['nin'],
      virtualAccountNumber: firstAccount?['accountNumber'] ?? json['virtualAccountNumber'],
      virtualBankName: firstAccount?['bankName'] ?? json['virtualBankName'] ?? 'Providus Bank',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'nin': nin,
      'virtualAccountNumber': virtualAccountNumber,
      'virtualBankName': virtualBankName,
    };
  }
}
