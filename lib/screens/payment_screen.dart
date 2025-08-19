import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../providers/booking_provider.dart';
import 'qr_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  BookingModel? _booking;
  ServiceModel? _service;
  String _selectedPaymentMethod = 'cash_on_service';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash_on_service',
      'title': 'Cash on Service',
      'subtitle': 'Pay after service completion',
      'icon': Icons.money,
      'color': Colors.green,
      'description':
          'Pay in cash when the service is completed to your satisfaction. This is the safest option.',
      'recommended': true,
    },
    {
      'id': 'upi_qr',
      'title': 'UPI QR Payment',
      'subtitle': 'Scan QR code with any UPI app',
      'icon': Icons.qr_code,
      'color': Colors.blue,
      'description':
          'Scan QR code with PhonePe, Google Pay, Paytm, or any UPI app. No transaction fees!',
      'recommended': true,
    },
  ];

  bool _isPostService = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _booking = args['booking'] as BookingModel?;
      _service = args['service'] as ServiceModel?;
      _isPostService = args['isPostService'] as bool? ?? false;

      // Handle automatic navigation parameters
      if (args['autoNavigated'] == true) {
        _isPostService = true;

        // If we have booking ID and amount, create a temporary booking model
        if (args['bookingId'] != null && args['amount'] != null) {
          final bookingId = args['bookingId'] as String;
          final amount = args['amount'] as double;
          final serviceType = args['serviceType'] as String?;

          // Create a minimal booking model for payment
          _booking = BookingModel(
            id: bookingId,
            userId: '', // Will be filled by provider
            serviceType: serviceType ?? 'service',
            customerName: 'Customer',
            customerPhone: '',
            customerAddress: '',
            description: '',
            preferredDate: DateTime.now(),
            preferredTime: '',
            status: 'completed',
            paymentStatus: 'pending',
            paymentMethod:
                'cash_on_service', // Add the required paymentMethod parameter
            actualAmount: amount,
            paymentAmount: amount,
            createdAt: DateTime.now(),
          );

          // Show auto-navigation message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '🎉 Your service is complete! Please proceed with payment.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          });
        }
      }
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (_selectedPaymentMethod == 'upi_qr') {
        await _processUpiQrPayment();
      } else {
        await _processCashPayment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processUpiQrPayment() async {
    if (_booking == null) return;

    final amount = _booking!.actualAmount ?? _booking!.paymentAmount ?? 0;
    
    // Navigate to QR payment screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QrPaymentScreen(
          booking: _booking!,
          amount: amount,
        ),
      ),
    );

    // If payment was confirmed, update the booking status
    if (result == true && mounted) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.completePayment(
        _booking!.id,
        amount,
        'upi_qr',
      );

      _showPaymentSuccessDialog();
    }
  }

  Future<void> _processCashPayment() async {
    if (_isPostService && _booking != null) {
      // Process post-service cash payment
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final actualAmount =
          _booking!.actualAmount ?? _booking!.paymentAmount ?? 0;

      final result = await bookingProvider.completePayment(
        _booking!.id,
        actualAmount,
        _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (result['success']) {
        _showPaymentSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Pre-service booking confirmation
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _showBookingConfirmationDialog();
    }
  }

  void _showBookingConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your service booking has been confirmed.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Service: ${_service?.displayName ?? 'N/A'}'),
                  Text(
                      'Date: ${_booking != null ? DateFormat('dd MMM yyyy').format(_booking!.preferredDate) : 'N/A'}'),
                  Text('Time: ${_booking?.preferredTime ?? 'N/A'}'),
                  Text('Amount: To be determined after service completion'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Our admin will review your booking and notify you once approved.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            child: Text('Go to Home'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessDialog({String? transactionId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your payment has been processed successfully.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Service: ${_service?.displayName ?? _booking?.serviceDisplayName ?? 'N/A'}'),
                  Text(
                      'Amount: ₹${_booking?.actualAmount?.toInt() ?? _booking?.paymentAmount?.toInt() ?? 0}'),
                  Text(
                      'Method: ${_getPaymentMethodName(_selectedPaymentMethod)}'),
                  if (transactionId != null)
                    Text('Transaction ID: $transactionId'),
                  Text(
                      'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Thank you for using our services!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            child: Text('Go to Home'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash_on_service':
        return 'Cash on Service';
      case 'upi_qr':
        return 'UPI QR Payment';
      default:
        return 'Cash on Service';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_service != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getServiceIcon(_service!.name),
                            color: Colors.deepPurple,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _service!.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                    ],
                    if (_booking != null) ...[
                      _buildSummaryRow('Customer', _booking!.customerName),
                      _buildSummaryRow('Phone', _booking!.customerPhone),
                      _buildSummaryRow(
                          'Date',
                          DateFormat('dd MMM yyyy')
                              .format(_booking!.preferredDate)),
                      _buildSummaryRow('Time', _booking!.preferredTime),
                      if (_booking!.description?.isNotEmpty == true)
                        _buildSummaryRow('Description', _booking!.description!),
                    ],
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isPostService
                              ? '₹${_booking?.actualAmount?.toInt() ?? _booking?.paymentAmount?.toInt() ?? 0}'
                              : 'To be determined after service completion',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Payment Methods
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: method['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            method['icon'],
                            color: method['color'],
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                method['subtitle'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: method['id'],
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                          activeColor: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 20),

            // Payment Note
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'cash_on_service'
                    ? Colors.blue[50]
                    : Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _selectedPaymentMethod == 'cash_on_service'
                        ? Colors.blue[200]!
                        : Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                      _selectedPaymentMethod == 'cash_on_service'
                          ? Icons.info
                          : Icons.security,
                      color: _selectedPaymentMethod == 'cash_on_service'
                          ? Colors.blue[600]
                          : Colors.purple[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPaymentMethod == 'cash_on_service'
                          ? 'You can pay in cash after the service is completed to your satisfaction.'
                          : 'Scan QR code with any UPI app (PhonePe, Google Pay, Paytm, etc.). No transaction fees!',
                      style: TextStyle(
                          color: _selectedPaymentMethod == 'cash_on_service'
                              ? Colors.blue[800]
                              : Colors.purple[800]),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Confirm Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        _isPostService
                            ? (_selectedPaymentMethod == 'cash_on_service'
                                ? 'Confirm Cash Payment ₹${_booking?.actualAmount?.toInt() ?? _booking?.paymentAmount?.toInt() ?? 0}'
                                : 'Pay via QR Code ₹${_booking?.actualAmount?.toInt() ?? _booking?.paymentAmount?.toInt() ?? 0}')
                            : (_selectedPaymentMethod == 'cash_on_service'
                                ? 'Confirm Booking'
                                : 'Pay ₹${_service?.basePrice.toInt() ?? 0}'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 16),

            // Security Note
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.grey[600], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'water_purifier':
        return Icons.water_drop;
      case 'ac_repair':
        return Icons.ac_unit;
      case 'refrigerator_repair':
        return Icons.kitchen;
      default:
        return Icons.build;
    }
  }
}
