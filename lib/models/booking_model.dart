class StatusHistoryEntry {
  final String status;
  final DateTime timestamp;
  final String? updatedBy;
  final String? notes;

  StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.notes,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      updatedBy: json['updatedBy'],
      notes: json['notes'],
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Admin Review';
      case 'accepted':
        return 'Accepted by Admin';
      case 'rejected':
        return 'Rejected';
      case 'assigned':
        return 'Worker Assigned';
      case 'in_progress':
        return 'Work in Progress';
      case 'completed':
        return 'Work Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class BookingModel {
  String id;
  final String userId;
  final String serviceType;
  String customerName;
  final String customerPhone;
  final String customerAddress;
  String? description;
  final DateTime preferredDate;
  DateTime get scheduledDate => preferredDate; // Alias for backend compatibility
  final String preferredTime;
  String status; // pending, accepted, rejected, assigned, in_progress, completed, cancelled
  List<StatusHistoryEntry> statusHistory;
  final String? assignedEmployee;
  final String? assignedEmployeeName;
  final String? assignedEmployeePhone;
  final DateTime? assignedDate;
  final DateTime? acceptedDate;
  final DateTime? rejectedDate;
  final DateTime? startedDate;
  final DateTime? completedDate;
  final String paymentStatus; // pending, paid, failed
  final String paymentMethod; // cash_on_service, online, cash_on_hand
  double? paymentAmount;
  final double? actualAmount; // Amount actually paid
  final String? adminNotes;
  final String? workerNotes;
  final String? rejectionReason;
  final DateTime createdAt;
  final Map<String, dynamic>? paymentProof;
  final Map<String, dynamic>? _serviceSpecificData; // Private field to store service-specific data

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.description,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
    List<StatusHistoryEntry>? statusHistory,
    this.assignedEmployee,
    this.assignedEmployeeName,
    this.assignedEmployeePhone,
    this.assignedDate,
    this.acceptedDate,
    this.rejectedDate,
    this.startedDate,
    this.completedDate,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentAmount,
    this.actualAmount,
    this.adminNotes,
    this.workerNotes,
    this.rejectionReason,
    required this.createdAt,
    this.paymentProof,
    Map<String, dynamic>? serviceSpecificData,
  }) : statusHistory = statusHistory ?? const [],
       _serviceSpecificData = serviceSpecificData;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Handle user field - it can be either a string (userId) or an object
    String userId = '';
    if (json['user'] != null) {
      if (json['user'] is String) {
        userId = json['user'];
      } else if (json['user'] is Map<String, dynamic>) {
        userId = json['user']['_id'] ?? json['user']['id'] ?? '';
      }
    }

    // Handle assigned employee field
    String? assignedEmployeeName;
    String? assignedEmployeePhone;
    if (json['assignedEmployee'] != null &&
        json['assignedEmployee'] is Map<String, dynamic>) {
      assignedEmployeeName = json['assignedEmployee']['name'];
      assignedEmployeePhone = json['assignedEmployee']['phone'];
    }

    // Handle status history
    List<StatusHistoryEntry> statusHistory = [];
    if (json['statusHistory'] != null && json['statusHistory'] is List) {
      statusHistory = (json['statusHistory'] as List)
          .map((entry) => StatusHistoryEntry.fromJson(entry))
          .toList();
    }

    // Extract service-specific data if available
    Map<String, dynamic>? serviceSpecificData;
    if (json['serviceSpecificData'] != null) {
      serviceSpecificData = Map<String, dynamic>.from(json['serviceSpecificData']);
    } else if (json['serviceDetails'] != null) {
      serviceSpecificData = Map<String, dynamic>.from(json['serviceDetails']);
    }
    
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      serviceType: json['serviceType'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      description: json['description'],
      preferredDate: _parseDateTime(json['preferredDate'] ?? json['scheduledDate']) ?? DateTime.now(),
      preferredTime: json['preferredTime'] ?? '',
      status: json['status'] ?? 'pending',
      statusHistory: statusHistory,
      assignedEmployee: json['assignedEmployee'] is String
          ? json['assignedEmployee']
          : json['assignedEmployee']?['_id'],
      assignedEmployeeName: assignedEmployeeName,
      assignedEmployeePhone: assignedEmployeePhone,
      assignedDate: _parseDateTime(json['assignedDate']),
      acceptedDate: _parseDateTime(json['acceptedDate']),
      rejectedDate: _parseDateTime(json['rejectedDate']),
      startedDate: _parseDateTime(json['startedDate']),
      completedDate: _parseDateTime(json['completedDate']),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cash_on_service',
      paymentAmount: json['paymentAmount']?.toDouble(),
      actualAmount: json['actualAmount']?.toDouble(),
      adminNotes: json['adminNotes'],
      workerNotes: json['workerNotes'],
      rejectionReason: json['rejectionReason'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      paymentProof: json['paymentProof'] as Map<String, dynamic>?,
      serviceSpecificData: serviceSpecificData,
    );
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return null;
    } catch (e) {
      print('❌ Error parsing date: $dateValue - $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'description': description,
      'preferredDate': preferredDate.toUtc().toIso8601String(),
      'scheduledDate': preferredDate.toUtc().toIso8601String(), // Backend compatibility
      'preferredTime': preferredTime,
      'paymentMethod': paymentMethod,
      'paymentAmount': paymentAmount,
      'adminNotes': adminNotes,
      'workerNotes': workerNotes,
      'serviceSpecificData': serviceSpecificData,
    };
  }

  String get serviceDisplayName {
    switch (serviceType) {
      case 'water_purifier':
        return 'Water Purifier Service';
      case 'ac_repair':
        return 'AC Repair Service';
      case 'refrigerator_repair':
        return 'Refrigerator Repair Service';
      default:
        return serviceType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Admin Review';
      case 'accepted':
        return 'Accepted by Admin';
      case 'rejected':
        return 'Rejected';
      case 'assigned':
        return 'Worker Assigned';
      case 'in_progress':
        return 'Work in Progress';
      case 'completed':
        return 'Work Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'cash_on_service':
        return 'Cash on Service';
      case 'cash_on_hand':
        return 'Cash in Hand';
      case 'online':
        return 'Online Payment';
      default:
        return paymentMethod;
    }
  }

  bool get canBeAccepted => status == 'pending';
  bool get canBeRejected => status == 'pending';
  bool get canAssignWorker => status == 'accepted';
  bool get canStartWork => status == 'assigned';
  bool get canCompleteWork => status == 'in_progress';
  bool get canProcessPayment =>
      status == 'completed' && paymentStatus == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isPaid => paymentStatus == 'paid';

  // Get estimated completion time based on current status
  DateTime? get estimatedCompletionTime {
    switch (status) {
      case 'pending':
        return createdAt.add(const Duration(hours: 24)); // 24 hours for admin review
      case 'accepted':
        return createdAt.add(const Duration(hours: 48)); // 48 hours for worker assignment
      case 'assigned':
        return preferredDate.add(const Duration(hours: 2)); // 2 hours after preferred time
      case 'in_progress':
        return startedDate?.add(const Duration(hours: 4)); // 4 hours for completion
      default:
        return null;
    }
  }

  // Get next expected action
  String get nextExpectedAction {
    switch (status) {
      case 'pending':
        return 'Waiting for admin review';
      case 'accepted':
        return 'Waiting for worker assignment';
      case 'assigned':
        return 'Worker will arrive on scheduled date';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return isPaid ? 'Service completed and paid' : 'Payment pending';
      case 'rejected':
        return 'Booking was rejected';
      case 'cancelled':
        return 'Booking was cancelled';
      default:
        return 'Unknown status';
    }
  }

  // Get progress percentage
  double get progressPercentage {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'accepted':
        return 0.4;
      case 'assigned':
        return 0.6;
      case 'in_progress':
        return 0.8;
      case 'completed':
        return isPaid ? 1.0 : 0.9;
      case 'rejected':
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
  }

  // Create a copy with updated fields
  BookingModel copyWith({
    String? id,
    String? userId,
    String? serviceType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? description,
    DateTime? preferredDate,
    String? preferredTime,
    String? status,
    List<StatusHistoryEntry>? statusHistory,
    String? assignedEmployee,
    String? assignedEmployeeName,
    String? assignedEmployeePhone,
    DateTime? assignedDate,
    DateTime? acceptedDate,
    DateTime? rejectedDate,
    DateTime? startedDate,
    DateTime? completedDate,
    String? paymentStatus,
    String? paymentMethod,
    double? paymentAmount,
    double? actualAmount,
    String? adminNotes,
    String? workerNotes,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      description: description ?? this.description,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      assignedEmployeePhone:
          assignedEmployeePhone ?? this.assignedEmployeePhone,
      assignedDate: assignedDate ?? this.assignedDate,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      startedDate: startedDate ?? this.startedDate,
      completedDate: completedDate ?? this.completedDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      adminNotes: adminNotes ?? this.adminNotes,
      workerNotes: workerNotes ?? this.workerNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Getter for service-specific data
  Map<String, dynamic> get serviceSpecificData {
    // If we have stored service-specific data, return it
    if (_serviceSpecificData != null) {
      return Map<String, dynamic>.from(_serviceSpecificData!);
    }
    
    // Otherwise, create default values based on service type
    final Map<String, dynamic> data = {};
    
    // Add service-specific fields based on service type
    if (serviceType == 'ac_repair') {
      // Default values for AC repair service
      data['acType'] = 'Split AC';
      data['acBrand'] = 'Generic';
      data['acCapacity'] = '1.5 Ton';
      data['installationYear'] = '2020';
      data['issueType'] = 'Not Cooling';
      data['roomSize'] = '150';
    } else if (serviceType == 'refrigerator_repair') {
      // Default values for refrigerator repair service
      data['fridgeType'] = 'Double Door';
      data['fridgeBrand'] = 'Generic';
      data['capacity'] = '300L';
    }
    
    return data; // Return the populated map
  }
}
