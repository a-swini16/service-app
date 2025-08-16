import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final BookingModel? booking;
  
  const PaymentProcessingScreen({Key? key, this.booking}) : super(key: key);

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  BookingModel? _booking;
  String? _paymentMethod;
  Map<String, dynamic>? _paymentMethodDetails;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  String _currentStatus = 'Initializing payment...';
  bool _isProcessing = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentResult;

  final List<String> _processingSteps = [
    'Initializing payment...',
    'Validating payment details...',
    'Processing with payment gateway...',
    'Confirming transaction...',
    'Updating booking status...',
    'Payment completed successfully!'
  ];

  int _currentStepIndex = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use widget booking if provided, otherwise get from route arguments
    if (widget.booking != null) {
      _booking = widget.booking;
    }
    
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _booking = _booking ?? args['booking'] as BookingModel?;
      _paymentMethod = args['paymentMethod'] as String?;
      _paymentMethodDetails =
          args['paymentMethodDetails'] as Map<String, dynamic>?;

      if (_booking != null && _paymentMethod != null) {
        _startPaymentProcess();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startPaymentProcess() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_currentStepIndex < _processingSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _currentStatus = _processingSteps[_currentStepIndex];
        });
      } else {
        timer.cancel();
        _processPayment();
      }
    });
  }

  Future<void> _processPayment() async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      if (_paymentMethod == 'cash_on_service') {
        // For cash payments, just update the booking
        final result = await bookingProvider.completePayment(
          _booking!.id,
          _booking!.actualAmount ?? _booking!.paymentAmount ?? 0.0,
          _paymentMethod!,
        );

        _handlePaymentResult(result);
      } else {
        // For online payments, create and process payment transaction
        final amount = _booking!.actualAmount ?? _booking!.paymentAmount ?? 0.0;

        // Create payment transaction
        final createResult = await ApiService.createPaymentTransaction({
          'bookingId': _booking!.id,
          'amount': amount,
          'paymentMethod': _paymentMethod!,
          'description': 'Payment for ${_booking!.serviceDisplayName}',
        });

        if (createResult['success']) {
          final transactionId = createResult['transaction']['transactionId'];

          // Process the payment
          final processResult = await ApiService.processPayment(transactionId, {
            'userContext': {
              'deviceInfo': 'mobile_app',
              'timestamp': DateTime.now().toIso8601String(),
            }
          });

          _handlePaymentResult(processResult);
        } else {
          _handlePaymentResult(createResult);
        }
      }
    } catch (error) {
      _handlePaymentResult({
        'success': false,
        'message': 'Payment processing failed: ${error.toString()}',
      });
    }
  }

  void _handlePaymentResult(Map<String, dynamic> result) {
    setState(() {
      _isProcessing = false;
      _paymentResult = result;

      if (result['success']) {
        _currentStatus = 'Payment completed successfully!';
        _animationController.stop();
        _animationController.reset();
      } else {
        _hasError = true;
        _errorMessage = result['message'] ?? 'Payment failed';
        _currentStatus = 'Payment failed';
        _animationController.stop();
      }
    });

    // Auto-navigate after success
    if (result['success']) {
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/payment-success',
            arguments: {
              'booking': _booking,
              'paymentResult': result,
              'paymentMethod': _paymentMethod,
            },
          );
        }
      });
    }
  }

  void _retryPayment() {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = null;
      _currentStepIndex = 0;
      _currentStatus = _processingSteps[0];
    });

    _animationController.repeat(reverse: true);
    _startPaymentProcess();
  }

  void _cancelPayment() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                if (!_hasError) ...[
                  const SizedBox(height: 40),
                  Text(
                    'Processing Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we process your payment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  Text(
                    'Payment Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There was an issue processing your payment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const Spacer(),

                // Animation and Status
                if (_isProcessing) ...[
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _paymentMethodDetails?['color'] ??
                                      Colors.blue,
                                  (_paymentMethodDetails?['color'] ??
                                          Colors.blue)
                                      .withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_paymentMethodDetails?['color'] ??
                                          Colors.blue)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _paymentMethodDetails?['icon'] ?? Icons.payment,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else if (_hasError) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red[300]!, width: 3),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red[700],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[100],
                      border: Border.all(color: Colors.green[300]!, width: 3),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 50,
                      color: Colors.green[700],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Status Text
                Text(
                  _currentStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _hasError ? Colors.red[700] : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_hasError && _errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Payment Details
                if (_booking != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Service',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _booking!.serviceDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₹${(_booking!.actualAmount ?? _booking!.paymentAmount ?? 0).toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _paymentMethodDetails?['title'] ??
                                  _paymentMethod ??
                                  'Unknown',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Action Buttons
                if (_hasError) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelPayment,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _retryPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _paymentMethodDetails?['color'] ?? Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Retry Payment'),
                        ),
                      ),
                    ],
                  ),
                ] else if (!_isProcessing) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Redirecting to confirmation...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
