class ServicePricing {
  // Service pricing configuration
  static const Map<String, Map<String, dynamic>> servicePrices = {
    'water_purifier': {
      'name': 'Water Purifier Service',
      'basePrice': 500,
      'description': 'Complete water purifier cleaning and maintenance',
      'includes': [
        'Filter cleaning/replacement',
        'Tank cleaning',
        'Water quality testing',
        'Performance check'
      ],
      'duration': '1-2 hours',
    },
    'ac_repair': {
      'name': 'AC Repair Service',
      'basePrice': 800,
      'description': 'Professional AC repair and maintenance',
      'includes': [
        'AC diagnosis',
        'Gas refilling (if needed)',
        'Filter cleaning',
        'Coil cleaning',
        'Performance testing'
      ],
      'duration': '2-3 hours',
    },
    'refrigerator_repair': {
      'name': 'Refrigerator Repair',
      'basePrice': 600,
      'description': 'Complete refrigerator repair service',
      'includes': [
        'Cooling system check',
        'Compressor diagnosis',
        'Temperature calibration',
        'Door seal inspection'
      ],
      'duration': '1-3 hours',
    },
  };

  /// Get service price by service type
  static Map<String, dynamic>? getServicePrice(String serviceType) {
    return servicePrices[serviceType];
  }

  /// Get base price for a service
  static int getBasePrice(String serviceType) {
    return servicePrices[serviceType]?['basePrice'] ?? 0;
  }

  /// Get service name
  static String getServiceName(String serviceType) {
    return servicePrices[serviceType]?['name'] ?? 'Unknown Service';
  }

  /// Get service description
  static String getServiceDescription(String serviceType) {
    return servicePrices[serviceType]?['description'] ?? '';
  }

  /// Get service includes list
  static List<String> getServiceIncludes(String serviceType) {
    return List<String>.from(servicePrices[serviceType]?['includes'] ?? []);
  }

  /// Get estimated duration
  static String getServiceDuration(String serviceType) {
    return servicePrices[serviceType]?['duration'] ?? 'Variable';
  }

  /// Calculate total price (can be extended for additional charges)
  static double calculateTotalPrice(String serviceType, {
    Map<String, dynamic>? additionalCharges,
  }) {
    double basePrice = getBasePrice(serviceType).toDouble();
    
    if (additionalCharges != null) {
      // Add any additional charges here
      // Example: parts cost, emergency charges, etc.
      basePrice += (additionalCharges['partsCharge'] ?? 0.0);
      basePrice += (additionalCharges['emergencyCharge'] ?? 0.0);
    }
    
    return basePrice;
  }

  /// Get all available services
  static List<Map<String, dynamic>> getAllServices() {
    return servicePrices.entries.map((entry) {
      return {
        'serviceType': entry.key,
        ...entry.value,
      };
    }).toList();
  }

  /// Format price for display
  static String formatPrice(double price) {
    return '₹${price.toInt()}';
  }

  /// Get payment methods for a service
  static List<Map<String, String>> getPaymentMethods(String serviceType) {
    return [
      {
        'id': 'cash_on_service',
        'name': 'Cash on Service',
        'description': 'Pay ${formatPrice(getBasePrice(serviceType).toDouble())} to the technician after service completion',
        'icon': '💵',
      },
      {
        'id': 'online',
        'name': 'Pay Online',
        'description': 'Pay ${formatPrice(getBasePrice(serviceType).toDouble())} online via UPI/QR code',
        'icon': '📱',
      },
    ];
  }
}