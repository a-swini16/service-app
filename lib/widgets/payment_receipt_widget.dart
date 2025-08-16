import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class PaymentReceiptWidget extends StatelessWidget {
  final BookingModel booking;
  final String? transactionId;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final bool showActions;

  const PaymentReceiptWidget({
    Key? key,
    required this.booking,
    this.transactionId,
    this.paymentMethod,
    this.paymentDate,
    this.showActions = true,
  }) : super(key: key);

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
        return method ?? 'Cash Payment';
    }
  }

  void _shareReceipt(BuildContext context) {
    // In a real app, this would share the receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share receipt feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    // In a real app, this would download a PDF receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download receipt feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Payment Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transactionId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Transaction ID: $transactionId',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Receipt Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Information
                _buildSectionHeader('Service Details'),
                const SizedBox(height: 12),
                _buildDetailRow('Service Type', booking.serviceDisplayName),
                _buildDetailRow('Booking ID', booking.id),
                _buildDetailRow('Customer Name', booking.customerName),
                _buildDetailRow('Phone Number', booking.customerPhone),
                _buildDetailRow('Service Address', booking.customerAddress),
                if (booking.assignedEmployeeName != null)
                  _buildDetailRow('Technician', booking.assignedEmployeeName!),

                const SizedBox(height: 20),

                // Payment Information
                _buildSectionHeader('Payment Information'),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Amount Paid',
                  '₹${(booking.actualAmount ?? booking.paymentAmount ?? 0).toInt()}',
                  isAmount: true,
                ),
                _buildDetailRow(
                  'Payment Method',
                  _getPaymentMethodDisplayName(
                      paymentMethod ?? booking.paymentMethod),
                ),
                _buildDetailRow(
                  'Payment Date',
                  DateFormat('dd MMM yyyy, hh:mm a').format(
                    paymentDate ?? booking.completedDate ?? DateTime.now(),
                  ),
                ),
                _buildDetailRow('Payment Status', 'Completed', isStatus: true),

                const SizedBox(height: 20),

                // Service Timeline
                if (booking.acceptedDate != null ||
                    booking.completedDate != null) ...[
                  _buildSectionHeader('Service Timeline'),
                  const SizedBox(height: 12),
                  if (booking.acceptedDate != null)
                    _buildDetailRow(
                      'Service Accepted',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(booking.acceptedDate!),
                    ),
                  if (booking.startedDate != null)
                    _buildDetailRow(
                      'Service Started',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(booking.startedDate!),
                    ),
                  if (booking.completedDate != null)
                    _buildDetailRow(
                      'Service Completed',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(booking.completedDate!),
                    ),
                  const SizedBox(height: 20),
                ],

                // Total Amount Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount Paid',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(booking.actualAmount ?? booking.paymentAmount ?? 0).toInt()}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),

                if (showActions) ...[
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareReceipt(context),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadReceipt(context),
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Thank you for choosing our services!',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For support, contact us at support@serviceapp.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isAmount = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontWeight:
                    isAmount || isStatus ? FontWeight.bold : FontWeight.w500,
                color: isAmount
                    ? Colors.green[700]
                    : isStatus
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
