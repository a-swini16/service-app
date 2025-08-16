import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final BookingModel? booking;
  
  const PaymentSuccessScreen({Key? key, this.booking}) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  BookingModel? _booking;
  Map<String, dynamic>? _paymentResult;
  String? _paymentMethod;

  late AnimationController _checkAnimationController;
  late AnimationController _confettiAnimationController;
  late Animation<double> _checkScaleAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _checkScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.elasticOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiAnimationController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _checkAnimationController.forward();
    _confettiAnimationController.forward();
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
      _paymentResult = args['paymentResult'] as Map<String, dynamic>?;
      _paymentMethod = args['paymentMethod'] as String?;
    }
  }

  @override
  void dispose() {
    _checkAnimationController.dispose();
    _confettiAnimationController.dispose();
    super.dispose();
  }

  String _getPaymentMethodDisplayName(String? method) {
    switch (method) {
      case 'cash_on_service':
        return 'Cash on Service';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      default:
        return 'Payment';
    }
  }

  String _getTransactionId() {
    if (_paymentResult?['transaction']?['transactionId'] != null) {
      return _paymentResult!['transaction']['transactionId'];
    }
    return 'TXN${DateTime.now().millisecondsSinceEpoch}';
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  void _viewBookingDetails() {
    Navigator.pushNamed(
      context,
      '/booking-details',
      arguments: {'booking': _booking},
    );
  }

  void _downloadReceipt() {
    // In a real app, this would generate and download a PDF receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt download feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goToHome();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.green[50],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Success Animation
                AnimatedBuilder(
                  animation: _checkAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkScaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green[500],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Success Title
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'Your payment has been processed successfully',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Payment Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Transaction ID',
                        _getTransactionId(),
                        isHighlighted: true,
                      ),
                      _buildDetailRow(
                        'Service',
                        _booking?.serviceDisplayName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Customer',
                        _booking?.customerName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Amount Paid',
                        '₹${(_booking?.actualAmount ?? _booking?.paymentAmount ?? 0).toInt()}',
                        isAmount: true,
                      ),
                      _buildDetailRow(
                        'Payment Method',
                        _getPaymentMethodDisplayName(_paymentMethod),
                      ),
                      _buildDetailRow(
                        'Date & Time',
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(DateTime.now()),
                      ),
                      if (_booking?.assignedEmployeeName != null)
                        _buildDetailRow(
                          'Technician',
                          _booking!.assignedEmployeeName!,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Service Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.blue[600],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Service Completed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your ${_booking?.serviceDisplayName ?? 'service'} has been completed successfully. Thank you for choosing our services!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Column(
                  children: [
                    // Primary Action - Go to Home
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _viewBookingDetails,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _downloadReceipt,
                            icon: const Icon(Icons.download),
                            label: const Text('Receipt'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Thank You Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Thank you for using our services! We hope to serve you again.',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false, bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted || isAmount
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isAmount
                    ? Colors.green[700]
                    : isHighlighted
                        ? Colors.blue[700]
                        : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
