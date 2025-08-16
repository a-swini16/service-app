import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class AdminPaymentStatusWidget extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onRefresh;

  const AdminPaymentStatusWidget({
    Key? key,
    required this.booking,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: _getPaymentStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment Status',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh payment status',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getPaymentStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPaymentStatusIcon(),
                    size: 16,
                    color: _getPaymentStatusColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getPaymentStatusText(),
                    style: TextStyle(
                      color: _getPaymentStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Details
            _buildDetailRow('Payment Method', _getPaymentMethodText()),
            if (booking.actualAmount != null || booking.paymentAmount != null)
              _buildDetailRow(
                'Amount',
                '₹${(booking.actualAmount ?? booking.paymentAmount ?? 0).toInt()}',
              ),
            
            // Service completion date
            if (booking.completedDate != null)
              _buildDetailRow(
                'Service Completed',
                DateFormat('dd MMM yyyy, hh:mm a').format(booking.completedDate!),
              ),

            // Payment received indicator
            if (booking.paymentStatus == 'paid') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment received successfully',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment pending warning
            if (booking.status == 'completed' && booking.paymentStatus == 'pending') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Service completed but payment is still pending',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment actions for admin
            if (booking.status == 'completed' && booking.paymentStatus == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markPaymentReceived(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark as Paid'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendPaymentReminder(context),
                      icon: const Icon(Icons.notifications, size: 18),
                      label: const Text('Send Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange[300]!),
                      ),
                    ),
                  ),
                ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Color _getPaymentStatusColor() {
    switch (booking.paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return booking.status == 'completed' ? Colors.orange : Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon() {
    switch (booking.paymentStatus) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return booking.status == 'completed' ? Icons.warning : Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getPaymentStatusText() {
    switch (booking.paymentStatus) {
      case 'paid':
        return 'Payment Received';
      case 'pending':
        return booking.status == 'completed' 
            ? 'Payment Pending' 
            : 'Awaiting Service Completion';
      case 'failed':
        return 'Payment Failed';
      default:
        return 'Unknown Status';
    }
  }

  String _getPaymentMethodText() {
    switch (booking.paymentMethod) {
      case 'cash_on_service':
        return 'Cash on Service';
      case 'upi':
        return 'UPI Payment (PhonePe)';
      case 'online':
        return 'Online Payment';
      default:
        return booking.paymentMethod;
    }
  }

  void _markPaymentReceived(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Payment as Received'),
        content: Text(
          'Are you sure you want to mark the payment of ₹${(booking.actualAmount ?? booking.paymentAmount ?? 0).toInt()} as received for ${booking.customerName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement mark payment as received
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment marked as received'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }

  void _sendPaymentReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Payment Reminder'),
        content: Text(
          'Send a payment reminder to ${booking.customerName} for the pending amount of ₹${(booking.actualAmount ?? booking.paymentAmount ?? 0).toInt()}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement send payment reminder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment reminder sent to customer'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }
}