import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class PaymentConfirmation {
  final String id;
  final String bookingId;
  final String customerName;
  final double amount;
  final String paymentMethod;
  final DateTime timestamp;
  final String status; // pending, verified, rejected

  PaymentConfirmation({
    required this.id,
    required this.bookingId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    this.status = 'pending',
  });
}

class AdminPaymentVerificationScreen extends StatefulWidget {
  const AdminPaymentVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AdminPaymentVerificationScreen> createState() => _AdminPaymentVerificationScreenState();
}

class _AdminPaymentVerificationScreenState extends State<AdminPaymentVerificationScreen> {
  List<PaymentConfirmation> pendingPayments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    setState(() {
      isLoading = true;
    });

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for demonstration
    setState(() {
      pendingPayments = [
        PaymentConfirmation(
          id: '1',
          bookingId: 'BOOK001',
          customerName: 'John Doe',
          amount: 500.0,
          paymentMethod: 'UPI QR',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        PaymentConfirmation(
          id: '2',
          bookingId: 'BOOK002',
          customerName: 'Jane Smith',
          amount: 800.0,
          paymentMethod: 'UPI QR',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verification'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPendingPayments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingPayments.isEmpty
              ? _buildEmptyState()
              : _buildPaymentsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No pending payments',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Payment confirmations will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return RefreshIndicator(
      onRefresh: _loadPendingPayments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingPayments.length,
        itemBuilder: (context, index) {
          final payment = pendingPayments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentConfirmation payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.qr_code,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${payment.amount.toInt()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        payment.paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Details
            _buildDetailRow('Customer', payment.customerName),
            _buildDetailRow('Booking ID', payment.bookingId),
            _buildDetailRow(
              'Time',
              DateFormat('dd MMM yyyy, hh:mm a').format(payment.timestamp),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Not Received'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPayment(payment),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirm Received'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment(PaymentConfirmation payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm that you have received payment of ₹${payment.amount.toInt()} from ${payment.customerName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'This will mark the booking as paid and complete.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPaymentConfirmation(payment, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Received'),
          ),
        ],
      ),
    );
  }

  void _rejectPayment(PaymentConfirmation payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Not Received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark payment of ₹${payment.amount.toInt()} from ${payment.customerName} as not received?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'The customer will be notified to make the payment again.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPaymentConfirmation(payment, false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Not Received'),
          ),
        ],
      ),
    );
  }

  void _processPaymentConfirmation(PaymentConfirmation payment, bool isConfirmed) {
    setState(() {
      pendingPayments.removeWhere((p) => p.id == payment.id);
    });

    // TODO: Send API call to update payment status
    // ApiService.updatePaymentStatus(payment.bookingId, isConfirmed ? 'paid' : 'failed');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConfirmed
              ? 'Payment confirmed for ${payment.customerName}'
              : 'Payment marked as not received for ${payment.customerName}',
        ),
        backgroundColor: isConfirmed ? Colors.green : Colors.red,
      ),
    );
  }
}