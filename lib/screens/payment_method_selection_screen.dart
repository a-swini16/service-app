import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_model.dart';
import '../constants/app_constants.dart';
import '../constants/service_pricing.dart';
import '../widgets/payment_amount_display_widget.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final BookingModel? booking;
  
  const PaymentMethodSelectionScreen({Key? key, this.booking}) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  BookingModel? _booking;
  String _selectedPaymentMethod = AppConstants.cashOnService;
  bool _isProcessing = false;

  List<Map<String, dynamic>> get _paymentMethods {
    final serviceAmount = ServicePricing.getBasePrice(_booking?.serviceType ?? '');
    return [
    {
      'id': AppConstants.cashOnService,
      'title': 'Cash on Service',
      'subtitle': 'Pay ₹$serviceAmount to technician after service completion',
      'icon': Icons.money,
      'color': Colors.green,
      'description':
          'Pay ₹$serviceAmount in cash when the service is completed to your satisfaction. This is the safest option as you pay only after the work is done.',
      'processingFee': 0.0,
      'recommended': true,
      'secure': true,
      'instantProcessing': false,
    },
    {
      'id': 'upi',
      'title': 'UPI Payment',
      'subtitle': 'Pay ₹$serviceAmount using UPI apps',
      'icon': Icons.payment,
      'color': Colors.blue,
      'description':
          'Quick and secure payment of ₹$serviceAmount using UPI apps like PhonePe, Google Pay, Paytm. Instant processing with bank-level security.',
      'processingFee': 0.0,
      'recommended': true,
      'secure': true,
      'instantProcessing': true,
    },
    {
      'id': 'card',
      'title': 'Credit/Debit Card',
      'subtitle': 'Pay using your card',
      'icon': Icons.credit_card,
      'color': Colors.purple,
      'description':
          'Secure payment using your credit or debit card. Protected by 3D Secure authentication and encrypted transactions.',
      'processingFee': 2.0,
      'recommended': false,
      'secure': true,
      'instantProcessing': true,
    },
    {
      'id': 'wallet',
      'title': 'Digital Wallet',
      'subtitle': 'Paytm, PhonePe, etc.',
      'icon': Icons.account_balance_wallet,
      'color': Colors.orange,
      'description':
          'Pay using your digital wallet balance. Quick and convenient with instant confirmation.',
      'processingFee': 1.0,
      'recommended': false,
      'secure': true,
      'instantProcessing': true,
    },
  ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use widget booking if provided, otherwise get from route arguments
    if (widget.booking != null) {
      _booking = widget.booking;
    } else {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _booking = args['booking'] as BookingModel?;
      }
    }
  }

  Future<void> _proceedWithPayment() async {
    if (_booking == null) return;

    // Validate payment method selection
    if (!_validatePaymentMethod()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();

      // Navigate to appropriate screen based on payment method
      if (_selectedPaymentMethod == AppConstants.cashOnService) {
        // For cash payments, show payment info screen
        final result = await Navigator.pushNamed(
          context,
          '/cash-payment-info',
          arguments: {
            'booking': _booking,
          },
        );

        if (result == true && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } else {
        // For online payments, go to secure payment form first
        final result = await Navigator.pushNamed(
          context,
          '/secure-payment-form',
          arguments: {
            'booking': _booking,
            'paymentMethod': _selectedPaymentMethod,
            'paymentMethodDetails': _getSelectedMethodDetails(),
          },
        );

        if (result == true && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _proceedWithPayment,
            ),
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

  bool _validatePaymentMethod() {
    final selectedMethod = _getSelectedMethodDetails();

    // Check if payment method is available
    if (selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid payment method'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Additional validation for online payment methods
    if (_selectedPaymentMethod != AppConstants.cashOnService) {
      // Check if amount is valid for online payment
      final amount = _calculateTotalAmount();
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid payment amount'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      // Check minimum amount for online payments
      if (amount < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimum amount for online payment is ₹10'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> _getSelectedMethodDetails() {
    return _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );
  }

  double _calculateTotalAmount() {
    if (_booking == null) return 0.0;

    final baseAmount = _booking!.actualAmount ?? _booking!.paymentAmount ?? 0.0;
    final selectedMethod = _getSelectedMethodDetails();
    final processingFee = selectedMethod['processingFee'] ?? 0.0;

    return baseAmount + (baseAmount * processingFee / 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method')),
        body: const Center(
          child: Text('No booking information found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        backgroundColor: Colors.blue[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getServiceIcon(_booking!.serviceType),
                          color: Colors.blue[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _booking!.serviceDisplayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Customer', _booking!.customerName),
                    _buildSummaryRow('Service Amount',
                        '₹${(_booking!.actualAmount ?? _booking!.paymentAmount ?? 0).toInt()}'),
                    if (_getSelectedMethodDetails()['processingFee'] > 0)
                      _buildSummaryRow(
                        'Processing Fee (${_getSelectedMethodDetails()['processingFee']}%)',
                        '₹${((_booking!.actualAmount ?? _booking!.paymentAmount ?? 0) * _getSelectedMethodDetails()['processingFee'] / 100).toInt()}',
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${_calculateTotalAmount().toInt()}',
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
            const SizedBox(height: 24),

            // Payment Amount Display
            PaymentAmountDisplayWidget(
              serviceType: _booking!.serviceType,
              paymentMethod: _selectedPaymentMethod,
              showDetails: true,
            ),
            const SizedBox(height: 24),

            // Payment Methods Section
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods List
            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? method['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Method Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: method['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                method['icon'],
                                color: method['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Method Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          method['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // Security indicator
                                      if (method['secure'])
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.security,
                                                size: 10,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Secure',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Instant processing indicator
                                      if (method['instantProcessing'])
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.flash_on,
                                                size: 10,
                                                color: Colors.purple[700],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Instant',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.purple[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Recommended badge
                                      if (method['recommended'])
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Recommended',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method['subtitle'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (method['processingFee'] > 0)
                                    Text(
                                      'Processing fee: ${method['processingFee']}%',
                                      style: TextStyle(
                                        color: Colors.orange[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Selection Radio
                            Radio<String>(
                              value: method['id'],
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                              activeColor: method['color'],
                            ),
                          ],
                        ),

                        // Method Description (shown when selected)
                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: method['color'].withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: method['color'].withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              method['description'],
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted. We use industry-standard security measures.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _proceedWithPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSelectedMethodDetails()['color'],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const Row(
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
                        'Proceed with ${_getSelectedMethodDetails()['title']} - ₹${_calculateTotalAmount().toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
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
