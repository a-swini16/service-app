import 'package:flutter/material.dart';
import 'package:om_enterprises/screens/user_notifications_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/service_provider.dart';
import 'providers/websocket_provider.dart';
import 'providers/offline_data_provider.dart';
import 'screens/admin_panel_screen.dart';
import 'services/onesignal_service.dart';

import 'services/navigation_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/water_purifier_screen.dart';
import 'screens/ac_service_screen.dart';
import 'screens/refrigerator_service_screen.dart';
import 'screens/dtdc_service_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/payment_screen.dart';
import 'models/service_model.dart';

import 'screens/user_menu_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/booking_details_screen.dart';
import 'screens/user_booking_status_screen.dart';
import 'screens/track_booking_screen.dart';
import 'screens/payment_method_selection_screen.dart';
import 'screens/secure_payment_form_screen.dart';
import 'screens/payment_processing_screen.dart';
import 'screens/payment_success_screen.dart';

import 'screens/qr_payment_screen.dart';
import 'screens/cash_payment_info_screen.dart';
import 'screens/payment_amount_form_screen.dart';

import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  await ApiService.initialize();

  // Initialize OneSignal notifications for production
  await OneSignalService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use a post-frame callback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
        
        switch (state) {
          case AppLifecycleState.resumed:
            // App in foreground, reconnect WebSocket
            wsProvider.handleAppLifecycleChange(true);
            break;
          case AppLifecycleState.paused:
          case AppLifecycleState.detached:
            // App in background or closed
            wsProvider.handleAppLifecycleChange(false);
            break;
          default:
            break;
        }
      } catch (e) {
        debugPrint('Error handling lifecycle change: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WebSocketProvider>(
          create: (context) => WebSocketProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? WebSocketProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (context) => BookingProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? BookingProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OfflineDataProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'Om Enterprises Service App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            primary: Colors.deepPurple,
            secondary: Colors.deepPurpleAccent,
            surface: Colors.grey[50]!,
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          fontFamily: 'Poppins',
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.lightBlue[50],
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/water-purifier': (context) => WaterPurifierScreen(),
          '/ac-service': (context) => AcServiceScreen(),
          '/refrigerator-service': (context) => RefrigeratorServiceScreen(),
          '/dtdc': (context) => DTDCServiceScreen(),
          '/booking-form': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String? serviceType;

            if (args is Map<String, dynamic>) {
              serviceType = args['serviceType'];
            } else if (args is ServiceModel) {
              serviceType = args.name;
            } else if (args is String) {
              serviceType = args;
            }

            return BookingFormScreen(serviceType: serviceType);
          },
          '/payment': (context) => const PaymentScreen(),
          '/payment-method-selection': (context) =>
              const PaymentMethodSelectionScreen(),
          '/secure-payment-form': (context) => const SecurePaymentFormScreen(),
          '/payment-processing': (context) => const PaymentProcessingScreen(),
          '/payment-success': (context) => const PaymentSuccessScreen(),
          '/user-menu': (context) => UserMenuScreen(),
          '/booking-details': (context) => const BookingDetailsScreen(),
          '/user-booking-status': (context) => const UserBookingStatusScreen(),
          '/track-booking': (context) => const TrackBookingScreen(),
          '/qr-payment': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return QrPaymentScreen(
              booking: args?['booking'],
              amount: args?['amount'] ?? 0.0,
            );
          },
          '/cash-payment-info': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return CashPaymentInfoScreen(
              booking: args?['booking'],
            );
          },
          '/payment-amount-form': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return PaymentAmountFormScreen(
              booking: args?['booking'],
              paymentMethod: args?['paymentMethod'] ?? 'cash_on_service',
            );
          },
          '/notifications': (context) => const UserNotificationsScreen(),
          '/admin': (context) => const AdminPanelScreen(),
        },
      ),
    );
  }
}
