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

  /// Get app package name for UPI apps
  static String? _getAppPackageName(String appName) {
    switch (appName.toLowerCase()) {
      case 'phonepe':
        return 'com.phonepe.app';
      case 'google pay':
      case 'googlepay':
        return 'com.google.android.apps.nbu.paisa.user';
      case 'paytm':
        return 'net.one97.paytm';
      case 'bhim':
        return 'in.org.npci.upiapp';
      default:
        return null;
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
      // Generate transaction note
      final note = customerName != null
          ? 'Service Payment - $bookingId - $customerName'
          : 'Service Payment - $bookingId';

      // Create the base UPI URL with all parameters
      final baseUpiUrl = 'upi://pay?pa=$businessUpiId'
          '&pn=${Uri.encodeComponent(businessName)}'
          '&am=${amount.toStringAsFixed(2)}'
          '&tn=${Uri.encodeComponent(note)}'
          '&cu=INR'
          '&mode=04';
      
      print('🔍 DEBUG: Base UPI URL: $baseUpiUrl');
      
      // Try to launch with specific app package if available
      final packageName = _getAppPackageName(appName);
      if (packageName != null) {
        // First try with package name for direct app launch
        try {
          final appSpecificUri = Uri.parse(baseUpiUrl);
          print('🔍 DEBUG: Trying to launch $appName with package: $packageName');
          
          final success = await launchUrl(
            appSpecificUri,
            mode: LaunchMode.externalApplication,
          );
          
          if (success) {
            print('✅ Successfully launched $appName');
            return true;
          }
        } catch (e) {
          print('⚠️ Error launching with package: $e');
          // Continue to try without package specification
        }
    }
      
      // Try to launch with standard URI
      print('🔍 DEBUG: Launching $appName with standard URL: $baseUpiUrl');
      if (await canLaunchUrl(Uri.parse(baseUpiUrl))) {
        final success = await launchUrl(
          Uri.parse(baseUpiUrl),
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          print('✅ Successfully launched UPI payment');
          return true;
        }
      }

      // If we get here, try the fallback method
      print('⚠️ Trying fallback method for UPI payment');
      return await _tryFallbackUpiLaunch(amount, bookingId, customerName);
    } catch (e) {
        print('❌ Error launching $appName: $e');
        // Fallback to generic UPI deep link
        return await _tryFallbackUpiLaunch(amount, bookingId, customerName);
    }
  }

  /// Try fallback methods for UPI payment launch
  static Future<bool> _tryFallbackUpiLaunch(
    double amount,
    String bookingId,
    String? customerName,
  ) async {
    try {
      // Generate transaction note
      final note = customerName != null
          ? 'Service Payment - $bookingId - $customerName'
          : 'Service Payment - $bookingId';
      
      // Try with the generic UPI URL first
      final genericUpiUrl = 'upi://pay?pa=$businessUpiId'
          '&pn=${Uri.encodeComponent(businessName)}'
          '&am=${amount.toStringAsFixed(2)}'
          '&tn=${Uri.encodeComponent(note)}'
          '&cu=INR';
      
      print('🔍 DEBUG: Trying generic UPI URL: $genericUpiUrl');
      
      if (await canLaunchUrl(Uri.parse(genericUpiUrl))) {
        final success = await launchUrl(
          Uri.parse(genericUpiUrl),
          mode: LaunchMode.externalApplication,
        );
        
        if (success) {
          print('✅ Successfully launched generic UPI payment');
          return true;
        }
      }
      
      // As a last resort, try the most basic UPI URL
      final basicUpiUrl = generateUpiUrl(
        upiId: businessUpiId,
        payeeName: businessName,
        amount: amount,
        transactionNote: note,
      );
      
      print('🔍 DEBUG: Trying basic UPI URL: $basicUpiUrl');
      
      if (await canLaunchUrl(Uri.parse(basicUpiUrl))) {
        final success = await launchUrl(
          Uri.parse(basicUpiUrl),
          mode: LaunchMode.externalApplication,
        );
        
        if (success) {
          print('✅ Successfully launched basic UPI payment');
          return true;
        }
      }
      
      print('❌ All UPI launch attempts failed');
      return false;
    } catch (e) {
      print('❌ Error in fallback UPI launch: $e');
      return false;
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
