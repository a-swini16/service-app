import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_model.dart';
import '../constants/service_pricing.dart';
import '../services/api_service.dart';

class PaymentAmountFormScreen extends StatefulWidget {
  final BookingModel booking;
  final String paymentMethod;

  const PaymentAmountFormScreen({
    Key? key,
    required this.booking,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<PaymentAmountFormScreen> createState() => _PaymentAmountFormScreenState();
}

class _PaymentAmountFormScreenState extends State<PaymentAmountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  
  late double _expectedAmount;
  late String _serviceName;

  @override
  void initState() {
    super.initState();
    _expectedAmount = ServicePricing.getBasePrice(widget.booking.serviceType).toDouble();
    _serviceName = ServicePricing.getServiceName(widget.booking.serviceType);
    
    // Pre-fill with expected amount
    _amountController.text = _expectedAmount.toInt().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment Amount'),
        backgroundColor: widget.paymentMethod == 'cash_on_service' 
            ? Colors.green 
            : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Summary Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.paymentMethod == 'cash_on_service' 
                                ? Icons.payments 
                                : Icons.qr_code,
                            color: widget.paymentMethod == 'cash_on_service' 
                                ? Colors.green 
                                : Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.paymentMethod == 'cash_on_service'
                                  ? 'Cash Payment Confirmation'
                                  : 'Online Payment Confirmation',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Service', _serviceName),
                      _buildDetailRow('Customer', widget.booking.customerName),
                      _buildDetailRow('Booking ID', widget.booking.id),
                      _buildDetailRow('Expected Amount', '₹${_expectedAmount.toInt()}'),
                      _buildDetailRow('Payment Method', 
                          widget.paymentMethod == 'cash_on_service' 
                              ? 'Cash on Service' 
                              : 'Online Payment'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Amount Input Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Payment Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount Input Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6), // Max 999999
                        ],
                        decoration: InputDecoration(
                          labelText: 'Amount Paid (₹)',
                          hintText: 'Enter the amount you paid',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.paymentMethod == 'cash_on_service' 
                                  ? Colors.green 
                                  : Colors.blue,
                              width: 2,
                            ),
                          ),
                          suffixText: '₹',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the payment amount';
                          }
                          
                          final amount = int.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          
                          if (amount > 50000) {
                            return 'Amount seems too high. Please verify.';
                          }
                          
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show amount difference
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Amount Comparison
                      if (_amountController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getAmountComparisonColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAmountComparisonColor().withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getAmountComparisonIcon(),
                                color: _getAmountComparisonColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getAmountComparisonText(),
                                  style: TextStyle(
                                    color: _getAmountComparisonColor(),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Quick Amount Buttons
                      const Text(
                        'Quick Select:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildQuickAmountButton(_expectedAmount.toInt()),
                          if (_expectedAmount >= 100)
                            _buildQuickAmountButton((_expectedAmount - 50).toInt()),
                          if (_expectedAmount <= 1000)
                            _buildQuickAmountButton((_expectedAmount + 50).toInt()),
                          _buildQuickAmountButton((_expectedAmount + 100).toInt()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Notes Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any notes about the payment (e.g., extra charges, discounts, etc.)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.paymentMethod == 'cash_on_service' 
                                  ? Colors.green 
                                  : Colors.blue,
                            ),
                          ),
                        ),
                        maxLength: 200,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPaymentAmount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.paymentMethod == 'cash_on_service' 
                        ? Colors.green 
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Confirming Payment...'),
                          ],
                        )
                      : const Text(
                          'Confirm Payment Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(int amount) {
    return OutlinedButton(
      onPressed: () {
        _amountController.text = amount.toString();
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.paymentMethod == 'cash_on_service' 
            ? Colors.green 
            : Colors.blue,
        side: BorderSide(
          color: widget.paymentMethod == 'cash_on_service' 
              ? Colors.green 
              : Colors.blue,
        ),
      ),
      child: Text('₹$amount'),
    );
  }

  Color _getAmountComparisonColor() {
    final enteredAmount = int.tryParse(_amountController.text) ?? 0;
    final expectedAmount = _expectedAmount.toInt();
    
    if (enteredAmount == expectedAmount) {
      return Colors.green;
    } else if (enteredAmount > expectedAmount) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getAmountComparisonIcon() {
    final enteredAmount = int.tryParse(_amountController.text) ?? 0;
    final expectedAmount = _expectedAmount.toInt();
    
    if (enteredAmount == expectedAmount) {
      return Icons.check_circle;
    } else if (enteredAmount > expectedAmount) {
      return Icons.arrow_upward;
    } else {
      return Icons.arrow_downward;
    }
  }

  String _getAmountComparisonText() {
    final enteredAmount = int.tryParse(_amountController.text) ?? 0;
    final expectedAmount = _expectedAmount.toInt();
    final difference = enteredAmount - expectedAmount;
    
    if (difference == 0) {
      return 'Amount matches expected price';
    } else if (difference > 0) {
      return 'Amount is ₹$difference more than expected';
    } else {
      return 'Amount is ₹${difference.abs()} less than expected';
    }
  }

  Future<void> _submitPaymentAmount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final enteredAmount = int.parse(_amountController.text);
      final notes = _notesController.text.trim();

      // Update booking with actual payment amount
      final response = await ApiService.put(
        '/bookings/${widget.booking.id}/payment-amount',
        {
          'actualAmount': enteredAmount,
          'expectedAmount': _expectedAmount.toInt(),
          'paymentMethod': widget.paymentMethod,
          'paymentNotes': notes.isEmpty ? null : notes,
          'paymentStatus': 'paid',
          'paidAt': DateTime.now().toIso8601String(),
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment amount confirmed: ₹$enteredAmount',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to success screen or home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/payment-success',
            (route) => false,
            arguments: {
              'booking': widget.booking,
              'amount': enteredAmount,
              'paymentMethod': widget.paymentMethod,
              'notes': notes,
            },
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to confirm payment amount');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}