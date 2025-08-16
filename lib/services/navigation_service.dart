import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<T?> navigateTo<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  static Future<T?> navigateAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and replace current route
  static Future<T?> navigateAndReplace<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  /// Go back to previous screen
  static void goBack<T extends Object?>([T? result]) {
    return navigator!.pop<T>(result);
  }

  /// Check if we can go back
  static bool canGoBack() {
    return navigator!.canPop();
  }

  /// Navigate to payment screen with booking data
  static Future<void> navigateToPayment({
    required String bookingId,
    required double amount,
    String? serviceType,
    bool isPostService = true,
  }) async {
    final arguments = {
      'bookingId': bookingId,
      'amount': amount,
      'serviceType': serviceType,
      'isPostService': isPostService,
      'autoNavigated': true, // Flag to indicate this was auto-navigated
    };

    await navigateTo('/payment', arguments: arguments);
  }

  /// Show payment required dialog
  static Future<void> showPaymentRequiredDialog({
    required String bookingId,
    required String serviceName,
    required double amount,
  }) async {
    if (context == null) return;

    return showDialog<void>(
      context: context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Payment Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your service has been completed successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service: $serviceName',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: ₹${amount.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please proceed to payment to complete your booking.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              navigateToPayment(
                bookingId: bookingId,
                amount: amount,
                serviceType: serviceName,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  /// Show service completion notification
  static Future<void> showServiceCompletionNotification({
    required String serviceName,
    required double amount,
    VoidCallback? onPayNowPressed,
  }) async {
    if (context == null) return;

    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Service Completed!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$serviceName - ₹${amount.toInt()}'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'PAY NOW',
          textColor: Colors.white,
          onPressed: onPayNowPressed ?? () {},
        ),
      ),
    );
  }

  /// Get current route name
  static String? getCurrentRouteName() {
    String? currentRouteName;
    navigator?.popUntil((route) {
      currentRouteName = route.settings.name;
      return true;
    });
    return currentRouteName;
  }

  /// Check if user is currently on a specific route
  static bool isCurrentRoute(String routeName) {
    return getCurrentRouteName() == routeName;
  }
}