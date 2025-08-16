import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../constants/app_constants.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  BookingModel? _booking;
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = AppConstants.cashOnService;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _booking = args['booking'] as BookingModel?;
      if (_booking != null) {
        _amountController.text = _booking!.paymentAmount?.toString() ?? '0';
        _selectedPaymentMethod = _booking!.paymentMethod;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_booking == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Navigate to payment processing screen
      final result = await Navigator.pushNamed(
        context,
        '/payment-processing',
        arguments: {
          'booking': _booking,
          'paymentMethod': _selectedPaymentMethod,
          'paymentMethodDetails': {
            'title': _getPaymentMethodDisplayName(_selectedPaymentMethod),
            'color': Colors.green,
            'icon': Icons.money,
          },
          'isAdminConfirmation': true,
          'actualAmount': amount,
        },
      );

      if (result == true && mounted) {
        // Payment successful, navigate back
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
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

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case AppConstants.cashOnService:
        return 'Cash on Service';
      case AppConstants.cashOnHand:
        return 'Cash in Hand';
      case AppConstants.onlinePayment:
        return 'Online Payment';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Confirmation')),
        body: const Center(
          child: Text('No booking information found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        backgroundColor: Colors.green[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Completion Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[100]!, Colors.green[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Service Completed Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your ${_booking!.serviceDisplayName} has been completed',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Service Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Service', _booking!.serviceDisplayName),
                    _buildDetailRow('Customer', _booking!.customerName),
                    _buildDetailRow('Phone', _booking!.customerPhone),
                    _buildDetailRow('Address', _booking!.customerAddress),
                    if (_booking!.assignedEmployeeName != null)
                      _buildDetailRow(
                          'Technician', _booking!.assignedEmployeeName!),
                    if (_booking!.completedDate != null)
                      _buildDetailRow(
                        'Completed On',
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(_booking!.completedDate!),
                      ),
                    if (_booking!.workerNotes?.isNotEmpty == true)
                      _buildDetailRow('Work Notes', _booking!.workerNotes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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

                    // Amount Input
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        helperText: 'Enter the actual amount paid by customer',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Selection
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Cash on Service'),
                          subtitle:
                              const Text('Customer paid in cash after service'),
                          value: AppConstants.cashOnService,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Cash in Hand'),
                          subtitle:
                              const Text('Customer paid in cash immediately'),
                          value: AppConstants.cashOnHand,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Online Payment'),
                          subtitle: const Text(
                              'Customer paid online (UPI/Card/Wallet)'),
                          value: AppConstants.onlinePayment,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Process Payment Button
            SizedBox(
              width: double.infinity,
              child: Consumer<BookingProvider>(
                builder: (context, bookingProvider, child) {
                  return ElevatedButton(
                    onPressed: (_isProcessing || bookingProvider.isLoading)
                        ? null
                        : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (_isProcessing || bookingProvider.isLoading)
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing Payment...'),
                            ],
                          )
                        : const Text(
                            'Confirm Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please confirm the payment details before proceeding. This action cannot be undone.',
                      style: TextStyle(color: Colors.blue[800]),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
