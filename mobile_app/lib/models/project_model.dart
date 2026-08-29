import 'property_model.dart';

class MilestoneModel {
  final String id;
  final String title;
  final String? description;
  final int percentage;
  final String status;
  final int orderIndex;
  final String? verifiedBy;

  MilestoneModel({
    required this.id,
    required this.title,
    this.description,
    required this.percentage,
    required this.status,
    required this.orderIndex,
    this.verifiedBy,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      percentage: json['percentage'] ?? 0,
      status: json['status'] ?? 'PENDING',
      orderIndex: json['orderIndex'] ?? 0,
      verifiedBy: json['verifiedBy'],
    );
  }
}

class ProjectUnitModel {
  final String id;
  final String unitType;
  final String name;
  final double price;
  final double initialDeposit;
  final int durationMonths;
  final double monthlyInstalment;
  final int availableUnits;
  final int totalUnits;
  final String status;

  ProjectUnitModel({
    required this.id,
    required this.unitType,
    required this.name,
    required this.price,
    required this.initialDeposit,
    required this.durationMonths,
    required this.monthlyInstalment,
    required this.availableUnits,
    required this.totalUnits,
    required this.status,
  });

  factory ProjectUnitModel.fromJson(Map<String, dynamic> json) {
    return ProjectUnitModel(
      id: json['id'] ?? '',
      unitType: json['unitType'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      initialDeposit: (json['initialDeposit'] as num?)?.toDouble() ?? 0.0,
      durationMonths: json['durationMonths'] ?? 12,
      monthlyInstalment: (json['monthlyInstalment'] as num?)?.toDouble() ?? 0.0,
      availableUnits: json['availableUnits'] ?? 1,
      totalUnits: json['totalUnits'] ?? 1,
      status: json['status'] ?? 'AVAILABLE',
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String state;
  final String city;
  final String area;
  final String address;
  final int totalUnits;
  final int availableUnits;
  final List<String> images;
  final String expectedCompletion;
  final String status;
  final bool isVerified;
  final DeveloperSummaryModel? developer;
  final List<MilestoneModel> milestones;
  final List<ProjectUnitModel> units;

  ProjectModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.state,
    required this.city,
    required this.area,
    required this.address,
    required this.totalUnits,
    required this.availableUnits,
    required this.images,
    required this.expectedCompletion,
    required this.status,
    required this.isVerified,
    this.developer,
    required this.milestones,
    required this.units,
  });

  String get firstImage => images.isNotEmpty ? images[0] : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600';

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<String> imageList = [];
    if (rawImages is List) {
      imageList = rawImages.map((e) => e.toString()).toList();
    }

    var ms = (json['milestones'] as List<dynamic>?)
            ?.map((m) => MilestoneModel.fromJson(m))
            .toList() ??
        [];

    var un = (json['units'] as List<dynamic>?)
            ?.map((u) => ProjectUnitModel.fromJson(u))
            .toList() ??
        [];

    return ProjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      totalUnits: json['totalUnits'] ?? 1,
      availableUnits: json['availableUnits'] ?? 1,
      images: imageList,
      expectedCompletion: json['expectedCompletion'] ?? '',
      status: json['status'] ?? 'UNDER_CONSTRUCTION',
      isVerified: json['isVerified'] ?? false,
      developer: json['developer'] != null
          ? DeveloperSummaryModel.fromJson(json['developer'])
          : null,
      milestones: ms,
      units: un,
    );
  }
}
