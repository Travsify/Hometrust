class PaymentPlanModel {
  final String id;
  final String name;
  final double totalPrice;
  final double initialDeposit;
  final int durationMonths;
  final double monthlyPayment;
  final String paymentFrequency;
  final double platformFee;

  PaymentPlanModel({
    required this.id,
    required this.name,
    required this.totalPrice,
    required this.initialDeposit,
    required this.durationMonths,
    required this.monthlyPayment,
    required this.paymentFrequency,
    required this.platformFee,
  });

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      initialDeposit: (json['initialDeposit'] as num?)?.toDouble() ?? 0.0,
      durationMonths: json['durationMonths'] ?? 12,
      monthlyPayment: (json['monthlyPayment'] as num?)?.toDouble() ?? 0.0,
      paymentFrequency: json['paymentFrequency'] ?? 'MONTHLY',
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 5000.0,
    );
  }
}

class DeveloperSummaryModel {
  final String id;
  final String companyName;
  final String cacNumber;
  final bool isVerified;
  final String verificationStatus;
  final String? logoUrl;
  final int completedProjectsCount;
  final int yearsOperating;

  DeveloperSummaryModel({
    required this.id,
    required this.companyName,
    required this.cacNumber,
    required this.isVerified,
    required this.verificationStatus,
    this.logoUrl,
    required this.completedProjectsCount,
    required this.yearsOperating,
  });

  factory DeveloperSummaryModel.fromJson(Map<String, dynamic> json) {
    return DeveloperSummaryModel(
      id: json['id'] ?? '',
      companyName: json['companyName'] ?? '',
      cacNumber: json['cacNumber'] ?? '',
      isVerified: json['isVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      logoUrl: json['logoUrl'],
      completedProjectsCount: json['completedProjectsCount'] ?? 0,
      yearsOperating: json['yearsOperating'] ?? 1,
    );
  }
}

class PropertyModel {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String listingType;
  final String state;
  final String city;
  final String area;
  final String address;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final String? landSize;
  final String landTitle;
  final String verificationStatus;
  final bool isFeatured;
  final List<String> images;
  final DeveloperSummaryModel? developer;
  final List<PaymentPlanModel> paymentPlans;

  PropertyModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.listingType,
    required this.state,
    required this.city,
    required this.area,
    required this.address,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    this.landSize,
    required this.landTitle,
    required this.verificationStatus,
    required this.isFeatured,
    required this.images,
    this.developer,
    required this.paymentPlans,
  });

  String get firstImage => images.isNotEmpty ? images[0] : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600';

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<String> imageList = [];
    if (rawImages is List) {
      imageList = rawImages.map((e) => e.toString()).toList();
    }

    var plans = (json['paymentPlans'] as List<dynamic>?)
            ?.map((p) => PaymentPlanModel.fromJson(p))
            .toList() ??
        [];

    return PropertyModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['propertyType'] ?? 'RESIDENTIAL',
      listingType: json['listingType'] ?? 'OUTRIGHT',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      landSize: json['landSize'],
      landTitle: json['landTitle'] ?? 'C_OF_O',
      verificationStatus: json['verificationStatus'] ?? 'VERIFIED',
      isFeatured: json['isFeatured'] ?? false,
      images: imageList,
      developer: json['developer'] != null
          ? DeveloperSummaryModel.fromJson(json['developer'])
          : null,
      paymentPlans: plans,
    );
  }
}
