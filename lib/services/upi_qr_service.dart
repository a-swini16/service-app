import 'package:url_launcher/url_launcher.dart';

class UpiQrService {
  // Your business UPI ID - Replace with your actual UPI ID
  static const String businessUpiId =
      'aswiniprasadrout-2@oksbi'; // Replace with your UPI ID
  static const String businessName =
      'Om Enterprises'; // Replace with your business name

  /// Generate UPI URL for QR code or direct payment
  static String generateUpiUrl({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
  }) {
    final amountStr = amount.toStringAsFixed(2);
    return 'upi://pay?pa=$upiId&pn=$payeeName&am=$amountStr&tn=$transactionNote';
  }

  /// Generate QR code data with booking details
  static String generateQrCodeData({
    required double amount,
    required String bookingId,
    String? customerName,
  }) {
    final note = customerName != null
        ? 'Service Payment - $bookingId - $customerName'
        : 'Service Payment - $bookingId';

    final upiUrl = generateUpiUrl(
      upiId: businessUpiId,
      payeeName: businessName,
      amount: amount,
      transactionNote: note,
    );

    // Debug print to verify the UPI URL
    print('🔍 DEBUG: Generated UPI URL: $upiUrl');
    print('🔍 DEBUG: Business UPI ID: $businessUpiId');
    print('🔍 DEBUG: Business Name: $businessName');

    return upiUrl;
  }

  /// Launch UPI app with payment details
  static Future<bool> launchUpiPayment({
    required double amount,
    required String bookingId,
    String? customerName,
  }) async {
    final upiUrl = generateQrCodeData(
      amount: amount,
      bookingId: bookingId,
      customerName: customerName,
    );

    try {
      if (await canLaunchUrl(Uri.parse(upiUrl))) {
        return await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Launch specific UPI app with payment details
  static Future<bool> launchSpecificUpiApp({
    required String appName,
    required double amount,
    required String bookingId,
    String? customerName,
  }) async {
    try {
      String deepLinkUrl;

      // Generate transaction note
      final note = customerName != null
          ? 'Service Payment - $bookingId - $customerName'
          : 'Service Payment - $bookingId';

      // App-specific deep links with amount and payment details
      switch (appName.toLowerCase()) {
        case 'phonepe':
          // PhonePe deep link format
          deepLinkUrl =
              'phonepe://pay?pa=$businessUpiId&pn=${Uri.encodeComponent(businessName)}&am=${amount.toStringAsFixed(2)}&tn=${Uri.encodeComponent(note)}';
          break;

        case 'google pay':
        case 'googlepay':
          // Google Pay deep link format
          deepLinkUrl =
              'gpay://upi/pay?pa=$businessUpiId&pn=${Uri.encodeComponent(businessName)}&am=${amount.toStringAsFixed(2)}&tn=${Uri.encodeComponent(note)}';
          break;

        case 'paytm':
          // Paytm deep link format
          deepLinkUrl =
              'paytmmp://pay?pa=$businessUpiId&pn=${Uri.encodeComponent(businessName)}&am=${amount.toStringAsFixed(2)}&tn=${Uri.encodeComponent(note)}';
          break;

        case 'bhim':
          // BHIM deep link format
          deepLinkUrl =
              'bhim://upi/pay?pa=$businessUpiId&pn=${Uri.encodeComponent(businessName)}&am=${amount.toStringAsFixed(2)}&tn=${Uri.encodeComponent(note)}';
          break;

        default:
          // Fallback to generic UPI deep link
          deepLinkUrl = generateUpiUrl(
            upiId: businessUpiId,
            payeeName: businessName,
            amount: amount,
            transactionNote: note,
          );
      }

      print('🔍 DEBUG: Launching $appName with URL: $deepLinkUrl');

      // Try to launch the specific app
      if (await canLaunchUrl(Uri.parse(deepLinkUrl))) {
        final success = await launchUrl(
          Uri.parse(deepLinkUrl),
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          print('✅ Successfully launched $appName');
          return true;
        }
      }

      // Fallback: Try generic UPI deep link
      print('⚠️ Fallback: Trying generic UPI deep link');
      return await launchUpiPayment(
        amount: amount,
        bookingId: bookingId,
        customerName: customerName,
      );
    } catch (e) {
      print('❌ Error launching $appName: $e');
      // Fallback to generic UPI deep link
      return await launchUpiPayment(
        amount: amount,
        bookingId: bookingId,
        customerName: customerName,
      );
    }
  }

  /// Get list of popular UPI apps
  static List<Map<String, dynamic>> getUpiApps() {
    return [
      {
        'name': 'PhonePe',
        'emoji': '📱',
        'color': '#5f259f',
      },
      {
        'name': 'Google Pay',
        'emoji': '💳',
        'color': '#4285f4',
      },
      {
        'name': 'Paytm',
        'emoji': '💰',
        'color': '#00baf2',
      },
      {
        'name': 'BHIM',
        'emoji': '🏛️',
        'color': '#0066cc',
      },
    ];
  }
}
