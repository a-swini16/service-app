import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/upi_qr_service.dart';
import '../services/payment_proof_service.dart';
import '../models/booking_model.dart';

class QrPaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final double amount;

  const QrPaymentScreen({
    Key? key,
    required this.booking,
    required this.amount,
  }) : super(key: key);

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  late String qrData;
  bool paymentConfirmed = false;
  bool isLoading = false;
  File? paymentProofImage;
  bool isUploadingProof = false;
  String? transactionId;

  @override
  void initState() {
    super.initState();
    qrData = UpiQrService.generateQrCodeData(
      amount: widget.amount,
      bookingId: widget.booking.id,
      customerName: widget.booking.customerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with UPI'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Payment Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 32,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        'Service', widget.booking.serviceDisplayName),
                    _buildDetailRow('Customer', widget.booking.customerName),
                    _buildDetailRow('Booking ID', widget.booking.id),
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${widget.amount.toInt()}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // QR Code Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '📱 Scan QR Code to Pay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Open any UPI app and scan this QR code',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // UPI Apps Section
            const Text(
              'Or pay using UPI apps:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: UpiQrService.getUpiApps().map((app) {
                return _buildUpiAppButton(
                  app['name'],
                  app['emoji'],
                  Color(int.parse(app['color'].substring(1), radix: 16) +
                      0xFF000000),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Manual UPI ID Section
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '💳 Or pay manually using UPI ID:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              UpiQrService.businessUpiId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyUpiId,
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            tooltip: 'Copy UPI ID',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${widget.amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Payment Proof Upload Section
            if (!paymentConfirmed) ...[
              Card(
                color: Colors.purple[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_alt,
                              color: Colors.purple, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '📸 Upload Payment Screenshot',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Take a screenshot of your payment confirmation and upload it for faster verification',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Image Preview or Upload Button
                      if (paymentProofImage != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              paymentProofImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectPaymentProof,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Change Image'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.purple,
                                  side: BorderSide(color: Colors.purple[300]!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    paymentProofImage = null;
                                  });
                                },
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Remove'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _selectPaymentProof,
                            icon: const Icon(Icons.add_a_photo, size: 20),
                            label: const Text('Upload Payment Screenshot'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: BorderSide(color: Colors.purple[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],

                      // Transaction ID Input (Optional)
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Transaction ID (Optional)',
                          hintText: 'Enter UPI transaction ID',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple[400]!),
                          ),
                        ),
                        onChanged: (value) {
                          transactionId =
                              value.trim().isEmpty ? null : value.trim();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Payment Confirmation Section
            if (!paymentConfirmed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'After making the payment, click the button below to confirm',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isLoading || isUploadingProof) ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: (isLoading || isUploadingProof)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(isUploadingProof
                                ? 'Uploading proof...'
                                : 'Processing...'),
                          ],
                        )
                      : const Text(
                          '✅ I have made the payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Payment Confirmation Sent!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Our admin will verify your payment and update the status shortly.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
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
    final success = await UpiQrService.launchSpecificUpiApp(
      appName: appName,
      amount: widget.amount,
      bookingId: widget.booking.id,
      customerName: widget.booking.customerName,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Unable to open $appName. Please ensure the app is installed.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Opening $appName with payment amount ₹${widget.amount.toInt()}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyUpiId() {
    Clipboard.setData(ClipboardData(text: UpiQrService.businessUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmPayment() async {
    setState(() {
      isLoading = true;
    });

    bool uploadSuccess = true;

    // Upload payment proof if provided
    if (paymentProofImage != null) {
      setState(() {
        isUploadingProof = true;
        isLoading = false;
      });

      uploadSuccess = await PaymentProofService.uploadPaymentProof(
        bookingId: widget.booking.id,
        imageFile: paymentProofImage!,
        amount: widget.amount,
        customerName: widget.booking.customerName,
        transactionId: transactionId,
      );

      setState(() {
        isUploadingProof = false;
      });

      if (!uploadSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to upload payment proof. You can try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      isLoading = true;
    });

    // Simulate API call to notify admin
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        paymentConfirmed = true;
        isLoading = false;
      });

      // Show success message
      String message = uploadSuccess && paymentProofImage != null
          ? 'Payment confirmation sent with screenshot! Admin will verify shortly.'
          : 'Payment confirmation sent! Admin will verify your payment.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Send notification to admin about payment confirmation
      _notifyAdmin();
    }
  }

  void _selectPaymentProof() async {
    final ImageSource? source =
        await PaymentProofService.showImageSourceDialog(context);
    if (source != null) {
      final File? imageFile =
          await PaymentProofService.pickPaymentProof(source: source);
      if (imageFile != null) {
        // Validate image
        if (!PaymentProofService.isValidImageFile(imageFile)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Please select a valid image file (JPG, JPEG, PNG)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check file size (max 5MB)
        if (PaymentProofService.getFileSizeInMB(imageFile) > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size should be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          paymentProofImage = imageFile;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment screenshot selected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _notifyAdmin() {
    // TODO: Implement API call to notify admin
    // Example:
    // ApiService.notifyPaymentConfirmation(
    //   bookingId: widget.booking.id,
    //   amount: widget.amount,
    //   customerName: widget.booking.customerName,
    // );
  }
}
