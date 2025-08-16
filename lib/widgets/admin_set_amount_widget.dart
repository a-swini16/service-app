import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_model.dart';

class AdminSetAmountWidget extends StatefulWidget {
  final BookingModel booking;
  final Function(double amount) onAmountSet;

  const AdminSetAmountWidget({
    Key? key,
    required this.booking,
    required this.onAmountSet,
  }) : super(key: key);

  @override
  State<AdminSetAmountWidget> createState() => _AdminSetAmountWidgetState();
}

class _AdminSetAmountWidgetState extends State<AdminSetAmountWidget> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  // Predefined service amounts for quick selection
  final List<Map<String, dynamic>> _quickAmounts = [
    {'label': '₹300', 'amount': 300, 'description': 'Basic service'},
    {'label': '₹500', 'amount': 500, 'description': 'Standard service'},
    {'label': '₹800', 'amount': 800, 'description': 'Premium service'},
    {'label': '₹1000', 'amount': 1000, 'description': 'Complex repair'},
    {'label': '₹1500', 'amount': 1500, 'description': 'Major repair'},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing amount if available
    if (widget.booking.actualAmount != null) {
      _amountController.text = widget.booking.actualAmount!.toInt().toString();
    } else if (widget.booking.paymentAmount != null) {
      _amountController.text = widget.booking.paymentAmount!.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    color: Colors.green[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Set Final Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Set the final amount to be charged for ${widget.booking.serviceDisplayName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Service Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${widget.booking.customerName}'),
                    Text('Service: ${widget.booking.serviceDisplayName}'),
                    Text('Address: ${widget.booking.customerAddress}'),
                    if (widget.booking.description?.isNotEmpty == true)
                      Text('Description: ${widget.booking.description}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Amount Selection
              const Text(
                'Quick Amount Selection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((quickAmount) {
                  return InkWell(
                    onTap: () {
                      _amountController.text = quickAmount['amount'].toString();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            quickAmount['label'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            quickAmount['description'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Custom Amount Input
              const Text(
                'Custom Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6), // Max 999999
                ],
                decoration: InputDecoration(
                  labelText: 'Final Amount (₹)',
                  hintText: 'Enter amount in rupees',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 50) {
                    return 'Minimum amount is ₹50';
                  }
                  if (amount > 50000) {
                    return 'Maximum amount is ₹50,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes about the service or pricing...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setAmount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Set Amount & Complete Service',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),

              // Info Note
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This amount will be charged to the customer. They will receive a payment notification immediately.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setAmount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set final amount to ₹${amount.toInt()} for:'),
              const SizedBox(height: 8),
              Text(
                '• Customer: ${widget.booking.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '• Service: ${widget.booking.serviceDisplayName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: ${_notesController.text}'),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'The customer will receive a payment notification immediately.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        widget.onAmountSet(amount);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Amount set to ₹${amount.toInt()}. Customer notified.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting amount: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}