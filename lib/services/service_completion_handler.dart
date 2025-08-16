import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'navigation_service.dart';

class ServiceCompletionHandler {
  static final ServiceCompletionHandler _instance = ServiceCompletionHandler._internal();
  factory ServiceCompletionHandler() => _instance;
  ServiceCompletionHandler._internal();

  /// Handle service completion notification
  static Future<void> handleServiceCompletion({
    required BookingModel booking,
    NotificationModel? notification,
  }) async {
    try {
      debugPrint('🎯 Service completion detected for booking: ${booking.id}');
      
      // Check if booking requires payment
      if (booking.status == 'completed' && 
          booking.paymentStatus == 'pending' &&
          (booking.actualAmount != null || booking.paymentAmount != null)) {
        
        final amount = booking.actualAmount ?? booking.paymentAmount ?? 0;
        final serviceName = booking.serviceDisplayName;
        
        debugPrint('💳 Payment required: ₹$amount for $serviceName');
        
        // Show immediate notification
        await NavigationService.showServiceCompletionNotification(
          serviceName: serviceName,
          amount: amount,
          onPayNowPressed: () => _navigateToPayment(booking),
        );
        
        // Wait a moment, then show dialog if user hasn't navigated away
        await Future.delayed(const Duration(seconds: 2));
        
        // Only show dialog if user is not already on payment screen
        if (!NavigationService.isCurrentRoute('/payment')) {
          await NavigationService.showPaymentRequiredDialog(
            bookingId: booking.id,
            serviceName: serviceName,
            amount: amount,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling service completion: $e');
    }
  }

  /// Handle payment required notification specifically
  static Future<void> handlePaymentRequiredNotification({
    required NotificationModel notification,
  }) async {
    try {
      debugPrint('💳 Payment required notification: ${notification.title}');
      
      // Extract booking data from notification
      final bookingId = notification.relatedBookingId;
      final data = notification.data;
      
      if (bookingId != null && data != null) {
        final amount = (data['actualAmount'] ?? data['paymentAmount'] ?? 0).toDouble();
        final serviceType = data['serviceType'] ?? 'Service';
        
        if (amount > 0) {
          // Show immediate notification
          await NavigationService.showServiceCompletionNotification(
            serviceName: serviceType,
            amount: amount,
            onPayNowPressed: () => NavigationService.navigateToPayment(
              bookingId: bookingId,
              amount: amount,
              serviceType: serviceType,
            ),
          );
          
          // Auto-navigate to payment after a short delay
          await Future.delayed(const Duration(seconds: 3));
          
          if (!NavigationService.isCurrentRoute('/payment')) {
            await NavigationService.navigateToPayment(
              bookingId: bookingId,
              amount: amount,
              serviceType: serviceType,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling payment required notification: $e');
    }
  }

  /// Navigate to payment screen
  static Future<void> _navigateToPayment(BookingModel booking) async {
    final amount = booking.actualAmount ?? booking.paymentAmount ?? 0;
    
    await NavigationService.navigateToPayment(
      bookingId: booking.id,
      amount: amount,
      serviceType: booking.serviceType,
    );
  }

  /// Handle booking status update
  static Future<void> handleBookingStatusUpdate({
    required String bookingId,
    required String newStatus,
    required String oldStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📊 Booking status update: $bookingId ($oldStatus → $newStatus)');
      
      // If status changed to completed, handle service completion
      if (newStatus == 'completed' && oldStatus != 'completed') {
        // We need booking data to handle completion properly
        // This would typically come from the WebSocket event or be fetched
        if (additionalData != null) {
          final amount = (additionalData['actualAmount'] ?? additionalData['paymentAmount'] ?? 0).toDouble();
          final serviceType = additionalData['serviceType'] ?? 'Service';
          
          if (amount > 0) {
            await NavigationService.showServiceCompletionNotification(
              serviceName: serviceType,
              amount: amount,
              onPayNowPressed: () => NavigationService.navigateToPayment(
                bookingId: bookingId,
                amount: amount,
                serviceType: serviceType,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling booking status update: $e');
    }
  }

  /// Check if automatic navigation should be triggered
  static bool shouldTriggerAutoNavigation({
    required String currentRoute,
    required BookingModel booking,
  }) {
    // Don't auto-navigate if already on payment screen
    if (currentRoute == '/payment') return false;
    
    // Don't auto-navigate if already on admin panel (admin might be working)
    if (currentRoute == '/admin') return false;
    
    // Only auto-navigate for completed bookings requiring payment
    if (booking.status != 'completed') return false;
    if (booking.paymentStatus != 'pending') return false;
    if ((booking.actualAmount ?? booking.paymentAmount ?? 0) <= 0) return false;
    
    return true;
  }

  /// Get service display name from service type
  static String getServiceDisplayName(String serviceType) {
    switch (serviceType) {
      case 'water_purifier':
        return 'Water Purifier Service';
      case 'ac_repair':
        return 'AC Repair Service';
      case 'refrigerator_repair':
        return 'Refrigerator Repair Service';
      default:
        return serviceType.replaceAll('_', ' ').toUpperCase();
    }
  }
}