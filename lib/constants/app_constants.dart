import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration - Live Production Backend
  static const String baseUrl = 'https://service-app-backend-6jpw.onrender.com/api';
  
  // Development URLs (commented out)
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // Windows/Desktop/iOS/Web
  // static const String baseUrl = 'http://192.168.1.100:5000/api'; // Physical Device
  
  // WebSocket URL - Live Production
  static const String socketUrl = 'https://service-app-backend-6jpw.onrender.com';
  
  // Environment
  static const String environment = 'production';
  
  // Service Types (must match backend enum)
  static const String waterPurifier = 'water_purifier';
  static const String acRepair = 'ac_repair';
  static const String refrigeratorRepair = 'refrigerator_repair';
  
  // Booking Status (must match backend enum)
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  
  // Payment Status (must match backend enum)
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  
  // Payment Methods (must match backend enum)
  static const String cashOnService = 'cash_on_service';
  static const String cashOnHand = 'cash_on_hand';
  static const String onlinePayment = 'online';
  
  // User Types
  static const String userTypeUser = 'user';
  static const String userTypeAdmin = 'admin';
  
  // Notification Types
  static const String notificationBookingCreated = 'booking_created';
  static const String notificationBookingAccepted = 'booking_accepted';
  static const String notificationBookingRejected = 'booking_rejected';
  static const String notificationWorkerAssigned = 'worker_assigned';
  static const String notificationServiceStarted = 'service_started';
  static const String notificationServiceCompleted = 'service_completed';
  static const String notificationPaymentRequired = 'payment_required';
  static const String notificationPaymentReceived = 'payment_received';
  
  // Service Display Names
  static const Map<String, String> serviceDisplayNames = {
    waterPurifier: 'Water Purifier Service',
    acRepair: 'AC Repair Service',
    refrigeratorRepair: 'Refrigerator Repair Service',
  };
  
  // Status Display Names
  static const Map<String, String> statusDisplayNames = {
    pending: 'Pending Review',
    accepted: 'Accepted',
    rejected: 'Rejected',
    assigned: 'Worker Assigned',
    inProgress: 'Service in Progress',
    completed: 'Service Completed - Payment Required',
    cancelled: 'Cancelled',
  };
  
  // Payment Method Display Names
  static const Map<String, String> paymentMethodDisplayNames = {
    cashOnService: 'Cash on Service',
    cashOnHand: 'Cash in Hand',
    onlinePayment: 'Online Payment',
    'upi': 'UPI Payment',
    'card': 'Credit/Debit Card',
    'wallet': 'Digital Wallet',
  };
  
  // Helper methods
  static String getServiceDisplayName(String serviceType) {
    return serviceDisplayNames[serviceType] ?? serviceType;
  }
  
  static String getStatusDisplayName(String status) {
    return statusDisplayNames[status] ?? status;
  }
  
  static String getPaymentMethodDisplayName(String paymentMethod) {
    return paymentMethodDisplayNames[paymentMethod] ?? paymentMethod;
  }
  
  // App Configuration
  static const int requestTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int cacheExpirationHours = 24;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const int animationDurationMs = 300;
  
  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  
  // Success Messages
  static const String bookingCreatedMessage = 'Booking created successfully!';
  static const String paymentCompletedMessage = 'Payment completed successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
}

class AppColors {
  static const primaryColor = Color(0xFF2196F3);
  static const secondaryColor = Color(0xFF03DAC6);
  static const errorColor = Color(0xFFB00020);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Color(0xFFFFFFFF);
}