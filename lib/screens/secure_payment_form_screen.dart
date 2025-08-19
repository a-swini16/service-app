import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:om_enterprises/models/booking_model.dart';
//import '../models/booking_model.dart';
import '../services/upi_qr_service.dart';

class SecurePaymentFormScreen extends StatefulWidget {
  const SecurePaymentFormScreen({Key? key}) : super(key: key);

  @override
  State<SecurePaymentFormScreen> createState() =>
      _SecurePaymentFormScreenState();
}

class _SecurePaymentFormScreenState extends State<SecurePaymentFormScreen> {
  BookingModel? _booking;
  String? _paymentMethod;
  Map<String, dynamic>? _paymentMethodDetails;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _walletPhoneController = TextEditingController();

  // Form state
  bool _isProcessing = false;
  bool _saveCardDetails = false;
  String _selectedCardType = '';

  // Focus nodes
  final _cardNumberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();
  final _cardHolderFocus = FocusNode();
  final _upiIdFocus = FocusNode();
  final _walletPhoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _booking = args['booking'] as BookingModel?;
      _paymentMethod = args['paymentMethod'] as String?;
      _paymentMethodDetails =
          args['paymentMethodDetails'] as Map<String, dynamic>?;
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _upiIdController.dispose();
    _walletPhoneController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _cardHolderFocus.dispose();
    _upiIdFocus.dispose();
    _walletPhoneFocus.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    setState(() {
      _selectedCardType = _getCardType(cardNumber);
    });
  }

  String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'visa';
    if (cardNumber.startsWith('5') || cardNumber.startsWith('2'))
      return 'mastercard';
    if (cardNumber.startsWith('3')) return 'amex';
    if (cardNumber.startsWith('6')) return 'rupay';
    return '';
  }

  Color _getCardColor(String cardType) {
    switch (cardType) {
      case 'visa':
        return Colors.blue[700]!;
      case 'mastercard':
        return Colors.red[700]!;
      case 'amex':
        return Colors.green[700]!;
      case 'rupay':
        return Colors.orange[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getCardDisplayName(String cardType) {
    switch (cardType) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MC';
      case 'amex':
        return 'AMEX';
      case 'rupay':
        return 'RUPAY';
      default:
        return 'CARD';
    }
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(' ', '');
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Invalid card number length';
    }

    if (!_isValidCardNumber(cardNumber)) {
      return 'Invalid card number';
    }

    return null;
  }

  bool _isValidCardNumber(String cardNumber) {
    // Luhn algorithm for card validation
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');

    if (month < 1 || month > 12) {
      return 'Invalid month';
    }

    final now = DateTime.now();
    final expiryDate = DateTime(year, month);

    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (value.length < 3 || value.length > 4) {
      return 'Invalid CVV';
    }

    return null;
  }

  String? _validateUPI(String? value) {
    if (value == null || value.isEmpty) {
      return 'UPI ID is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(value)) {
      return 'Invalid UPI ID format';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Invalid phone number';
    }

    return null;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Prepare payment data based on method
      Map<String, dynamic> paymentData = {
        'booking': _booking,
        'paymentMethod': _paymentMethod,
        'paymentMethodDetails': _paymentMethodDetails,
      };

      // Add method-specific data
      switch (_paymentMethod) {
        case 'card':
          paymentData['cardDetails'] = {
            'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
            'expiryDate': _expiryController.text,
            'cvv': _cvvController.text,
            'cardHolderName': _cardHolderController.text,
            'cardType': _selectedCardType,
            'saveCard': _saveCardDetails,
          };
          break;
        case 'upi':
          paymentData['upiDetails'] = {
            'upiId': _upiIdController.text,
          };
          break;
        case 'wallet':
          paymentData['walletDetails'] = {
            'phoneNumber': _walletPhoneController.text,
          };
          break;
      }

      // Navigate to payment processing
      final result = await Navigator.pushNamed(
        context,
        '/payment-processing',
        arguments: paymentData,
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    if (_booking == null || _paymentMethod == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Form')),
        body: const Center(
          child: Text('Invalid payment information'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_paymentMethodDetails?['title'] ?? 'Payment'} Details'),
        backgroundColor: Colors.blue[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            'Your payment information is encrypted and secure',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Amount Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_booking!.serviceDisplayName),
                        Text(
                            '₹${(_booking!.actualAmount ?? _booking!.paymentAmount ?? 0).toInt()}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show service details based on service type
                    if (_booking!.serviceType == 'ac_repair' || _booking!.serviceType == 'refrigerator_repair' || _booking!.serviceType == 'water_purifier')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Details:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Display specific details for AC repair
                            if (_booking!.serviceType == 'ac_repair') ...[                              
                              _buildServiceDetailRow('AC Type', _booking!.serviceSpecificData['acType'] ?? 'Not specified'),
                              _buildServiceDetailRow('AC Brand', _booking!.serviceSpecificData['acBrand'] ?? 'Not specified'),
                              _buildServiceDetailRow('AC Capacity', _booking!.serviceSpecificData['acCapacity'] ?? 'Not specified'),
                              _buildServiceDetailRow('Installation Year', _booking!.serviceSpecificData['installationYear'] ?? 'Not specified'),
                              _buildServiceDetailRow('Primary Issue', _booking!.serviceSpecificData['issueType'] ?? 'Not specified'),
                              _buildServiceDetailRow('Room Size', _booking!.serviceSpecificData['roomSize'] != null ? '${_booking!.serviceSpecificData['roomSize']} Sq Ft' : 'Not specified'),
                            ] else if (_booking!.serviceType == 'refrigerator_repair') ...[                              
                              _buildServiceDetailRow('Refrigerator Type', _booking!.serviceSpecificData['fridgeType'] ?? 'Not specified'),
                              _buildServiceDetailRow('Brand', _booking!.serviceSpecificData['fridgeBrand'] ?? 'Not specified'),
                              _buildServiceDetailRow('Capacity', _booking!.serviceSpecificData['capacity'] ?? 'Not specified'),
                              _buildServiceDetailRow('Purchase Year', _booking!.serviceSpecificData['purchaseYear'] ?? 'Not specified'),
                              _buildServiceDetailRow('Primary Issue', _booking!.serviceSpecificData['issueType'] ?? 'Not specified'),
                            ], // Added comma here 
                            if (_booking!.serviceType != 'ac_repair' && _booking!.serviceType != 'refrigerator_repair')
                              Text(
                                _booking!.description ?? 'No specific details provided',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${(_booking!.actualAmount ?? _booking!.paymentAmount ?? 0).toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Form based on method
              if (_paymentMethod == 'card') ..._buildCardForm(),
              if (_paymentMethod == 'upi') ..._buildUPIForm(),
              if (_paymentMethod == 'wallet') ..._buildWalletForm(),

              const SizedBox(height: 32),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _paymentMethodDetails?['color'] ?? Colors.blue,
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
                          'Pay ₹${(_booking!.actualAmount ?? _booking!.paymentAmount ?? 0).toInt()}',
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
      ),
    );
  }

  List<Widget> _buildCardForm() {
    return [
      const Text(
        'Card Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),

      // Card Number
      TextFormField(
        controller: _cardNumberController,
        focusNode: _cardNumberFocus,
        decoration: InputDecoration(
          labelText: 'Card Number',
          hintText: '1234 5678 9012 3456',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.credit_card),
          suffixIcon: _selectedCardType.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 32,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getCardColor(_selectedCardType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _getCardDisplayName(_selectedCardType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(19),
          _CardNumberInputFormatter(),
        ],
        validator: _validateCardNumber,
        onFieldSubmitted: (_) => _expiryFocus.requestFocus(),
      ),
      const SizedBox(height: 16),

      // Expiry and CVV
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _expiryController,
              focusNode: _expiryFocus,
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                hintText: 'MM/YY',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
                _ExpiryDateInputFormatter(),
              ],
              validator: _validateExpiry,
              onFieldSubmitted: (_) => _cvvFocus.requestFocus(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _cvvController,
              focusNode: _cvvFocus,
              decoration: const InputDecoration(
                labelText: 'CVV',
                hintText: '123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: _validateCVV,
              obscureText: true,
              onFieldSubmitted: (_) => _cardHolderFocus.requestFocus(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Card Holder Name
      TextFormField(
        controller: _cardHolderController,
        focusNode: _cardHolderFocus,
        decoration: const InputDecoration(
          labelText: 'Card Holder Name',
          hintText: 'John Doe',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        textCapitalization: TextCapitalization.words,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Card holder name is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Save Card Option
      CheckboxListTile(
        title: const Text('Save card for future payments'),
        subtitle: const Text('Your card details will be securely stored'),
        value: _saveCardDetails,
        onChanged: (value) {
          setState(() {
            _saveCardDetails = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
  }

  List<Widget> _buildUPIForm() {
    return [
      const Text(
        'UPI Payment',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _upiIdController,
        focusNode: _upiIdFocus,
        decoration: const InputDecoration(
          labelText: 'UPI ID',
          hintText: 'yourname@paytm',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.account_balance_wallet),
          helperText: 'Enter your UPI ID (e.g., 9876543210@paytm)',
        ),
        keyboardType: TextInputType.emailAddress,
        validator: _validateUPI,
      ),
      const SizedBox(height: 24),
      const Text(
        'Or pay directly using UPI apps:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildUpiAppButton(
            'PhonePe',
            '📱',
            Color(0xFF5f259f),
          ),
          _buildUpiAppButton(
            'Google Pay',
            '💳',
            Color(0xFF4285f4),
          ),
          _buildUpiAppButton(
            'Paytm',
            '💰',
            Color(0xFF00baf2),
          ),
          _buildUpiAppButton(
            'BHIM',
            '🏛️',
            Color(0xFF0066cc),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular UPI IDs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            const Text('• PhonePe: yourphone@ybl'),
            const Text('• Google Pay: yourphone@okaxis'),
            const Text('• Paytm: yourphone@paytm'),
            const Text('• BHIM: yourphone@upi'),
          ],
        ),
      ),
    ];
  }
  
  Widget _buildUpiAppButton(String appName, String emoji, Color color) {
    return GestureDetector(
      onTap: () => _launchSpecificUpiApp(appName),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _launchSpecificUpiApp(String appName) async {
    if (_booking == null) return;
    
    final amount = _booking!.actualAmount ?? _booking!.paymentAmount ?? 0.0;
    final bookingId = _booking!.id;
    final customerName = _booking!.customerName;
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Launching UPI payment...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final success = await UpiQrService.launchSpecificUpiApp(
        appName: appName,
        amount: amount,
        bookingId: bookingId,
        customerName: customerName,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to open $appName. Please ensure the app is installed.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Try Generic',
              onPressed: () {
                UpiQrService.launchUpiPayment(
                  amount: amount,
                  bookingId: bookingId,
                  customerName: customerName,
                );
              },
            ),
          ),
        );
      } else if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Opening $appName with payment amount ₹${amount.toInt()}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching UPI app: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Widget> _buildWalletForm() {
    return [
      const Text(
        'Digital Wallet',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _walletPhoneController,
        focusNode: _walletPhoneFocus,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: '9876543210',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.phone),
          prefixText: '+91 ',
          helperText: 'Enter phone number linked to your wallet',
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Phone number is required';
          }
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
            return 'Invalid phone number';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Wallets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Paytm Wallet'),
            const Text('• PhonePe Wallet'),
            const Text('• Amazon Pay'),
            const Text('• Mobikwik'),
          ],
        ),
      ),
    ];
  }
}

// Input formatters
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

  // Helper method to build service detail rows
  Widget _buildServiceDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.blue[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }


class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length == 2 && oldValue.text.length == 1) {
      return TextEditingValue(
        text: '$text/',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    return newValue;
  }
}
