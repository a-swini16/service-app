class WorkerModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final List<String> skills;
  final String experience;
  final bool isAvailable;
  final double? rating;
  final int? completedJobs;
  final String? profileImage;
  final String? aadharNumber;
  final String? panNumber;
  final bool isVerified;
  final DateTime? joinedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkerModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.skills = const [],
    this.experience = '0 years',
    this.isAvailable = true,
    this.rating,
    this.completedJobs = 0,
    this.profileImage,
    this.aadharNumber,
    this.panNumber,
    this.isVerified = false,
    this.joinedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      skills: json['skills'] != null 
          ? List<String>.from(json['skills']) 
          : [],
      experience: json['experience'] ?? '0 years',
      isAvailable: json['isAvailable'] ?? true,
      rating: json['rating']?.toDouble(),
      completedJobs: json['completedJobs'] ?? 0,
      profileImage: json['profileImage'],
      aadharNumber: json['aadharNumber'],
      panNumber: json['panNumber'],
      isVerified: json['isVerified'] ?? false,
      joinedDate: json['joinedDate'] != null 
          ? DateTime.parse(json['joinedDate']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      if (address != null) 'address': address,
      'skills': skills,
      'experience': experience,
      'isAvailable': isAvailable,
      if (rating != null) 'rating': rating,
      'completedJobs': completedJobs,
      if (profileImage != null) 'profileImage': profileImage,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (panNumber != null) 'panNumber': panNumber,
      'isVerified': isVerified,
      if (joinedDate != null) 'joinedDate': joinedDate!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  WorkerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    List<String>? skills,
    String? experience,
    bool? isAvailable,
    double? rating,
    int? completedJobs,
    String? profileImage,
    String? aadharNumber,
    String? panNumber,
    bool? isVerified,
    DateTime? joinedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      profileImage: profileImage ?? this.profileImage,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      panNumber: panNumber ?? this.panNumber,
      isVerified: isVerified ?? this.isVerified,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get formattedRating {
    if (rating == null) return 'No rating';
    return '${rating!.toStringAsFixed(1)}/5.0';
  }

  String get availabilityStatus => isAvailable ? 'Available' : 'Busy';

  String get verificationStatus => isVerified ? 'Verified' : 'Pending';

  String get skillsText => skills.isEmpty ? 'No skills listed' : skills.join(', ');

  String get experienceText => experience.isEmpty ? 'No experience listed' : experience;

  // Get availability color for UI
  String get availabilityColor {
    return isAvailable ? '#4CAF50' : '#F44336'; // Green for available, Red for busy
  }

  // Get verification color for UI
  String get verificationColor {
    return isVerified ? '#4CAF50' : '#FFA500'; // Green for verified, Orange for pending
  }

  @override
  String toString() {
    return 'WorkerModel(id: $id, name: $name, skills: $skillsText, available: $isAvailable)';
  }
}

// Worker skills enum
enum WorkerSkill {
  waterPurifierRepair,
  acRepair,
  refrigeratorRepair,
  electricalWork,
  plumbing,
  cleaning,
  installation,
  maintenance,
}

extension WorkerSkillExtension on WorkerSkill {
  String get value {
    switch (this) {
      case WorkerSkill.waterPurifierRepair:
        return 'water-purifier-repair';
      case WorkerSkill.acRepair:
        return 'ac-repair';
      case WorkerSkill.refrigeratorRepair:
        return 'refrigerator-repair';
      case WorkerSkill.electricalWork:
        return 'electrical-work';
      case WorkerSkill.plumbing:
        return 'plumbing';
      case WorkerSkill.cleaning:
        return 'cleaning';
      case WorkerSkill.installation:
        return 'installation';
      case WorkerSkill.maintenance:
        return 'maintenance';
    }
  }

  String get displayName {
    switch (this) {
      case WorkerSkill.waterPurifierRepair:
        return 'Water Purifier Repair';
      case WorkerSkill.acRepair:
        return 'AC Repair';
      case WorkerSkill.refrigeratorRepair:
        return 'Refrigerator Repair';
      case WorkerSkill.electricalWork:
        return 'Electrical Work';
      case WorkerSkill.plumbing:
        return 'Plumbing';
      case WorkerSkill.cleaning:
        return 'Cleaning';
      case WorkerSkill.installation:
        return 'Installation';
      case WorkerSkill.maintenance:
        return 'Maintenance';
    }
  }
}
