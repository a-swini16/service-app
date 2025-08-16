class ServiceModel {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final double basePrice;
  final int duration;
  final String category;
  final bool isActive;
  final String? imageUrl;

  ServiceModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.basePrice,
    required this.duration,
    required this.category,
    this.isActive = true,
    this.imageUrl,
  });

  // Backward compatibility getter
  double get price => basePrice;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      category: json['category'] ?? '',
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
    );
  }

  static List<ServiceModel> getDefaultServices() {
    return [
      ServiceModel(
        id: '1',
        name: 'water_purifier',
        displayName: 'Water Purifier Service',
        description: 'Complete water purifier maintenance and repair service',
        basePrice: 500.0,
        duration: 60,
        category: 'Home Appliances',
        imageUrl: 'assets/images/water_purifier.png',
      ),
      ServiceModel(
        id: '2',
        name: 'ac_repair',
        displayName: 'AC Repair Service',
        description: 'Professional AC repair and maintenance service',
        basePrice: 800.0,
        duration: 90,
        category: 'Home Appliances',
        imageUrl: 'assets/images/ac_repair.png',
      ),
      ServiceModel(
        id: '3',
        name: 'refrigerator_repair',
        displayName: 'Refrigerator Repair Service',
        description: 'Expert refrigerator repair and maintenance service',
        basePrice: 700.0,
        duration: 75,
        category: 'Home Appliances',
        imageUrl: 'assets/images/refrigerator_repair.png',
      ),
      ServiceModel(
        id: '4',
        name: 'dtdc_service',
        displayName: 'DTDC Express',
        description: 'Courier and logistics services',
        basePrice: 0.0,
        duration: 0,
        category: 'Logistics',
        imageUrl: 'assets/images/dtdc.png',
      ),
    ];
  }
}