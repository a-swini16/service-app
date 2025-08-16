import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final ServiceModel service;
  final String bookingId;

  const BookingConfirmationScreen({
    Key? key,
    required this.bookingData,
    required this.service,
    required this.bookingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Icon and Message
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: $bookingId',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Service Details Card
            _buildServiceDetailsCard(),
            const SizedBox(height: 16),

            // Customer Details Card
            _buildCustomerDetailsCard(),
            const SizedBox(height: 16),

            // Timeline Card
            _buildTimelineCard(),
            const SizedBox(height: 16),

            // Service-specific details if available
            if (bookingData.containsKey('serviceDetails'))
              _buildServiceSpecificDetailsCard(),
            const SizedBox(height: 16),

            // Important Notes Card
            _buildImportantNotesCard(),
            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getServiceIcon(service.name),
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Service', service.displayName),
            _buildDetailRow('Estimated Duration', '${service.duration} minutes'),
            _buildDetailRow('Base Price', '₹${service.basePrice.toInt()}'),
            _buildDetailRow('Payment Method', _getPaymentMethodDisplay(bookingData['paymentMethod'])),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Name', bookingData['customerName']),
            _buildDetailRow('Phone', bookingData['customerPhone']),
            _buildDetailRow('Address', bookingData['customerAddress']),
            if (bookingData['description'] != null && bookingData['description'].toString().isNotEmpty)
              _buildDetailRow('Description', bookingData['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final preferredDate = DateTime.parse(bookingData['preferredDate']);
    final preferredTime = bookingData['preferredTime'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Expected Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineStep(
              'Booking Submitted',
              'Just now',
              Icons.check_circle,
              Colors.green,
              isCompleted: true,
            ),
            _buildTimelineStep(
              'Admin Review',
              'Within 30 minutes',
              Icons.admin_panel_settings,
              Colors.orange,
              isCompleted: false,
            ),
            _buildTimelineStep(
              'Worker Assignment',
              'Within 2 hours',
              Icons.person_add,
              Colors.blue,
              isCompleted: false,
            ),
            _buildTimelineStep(
              'Service Scheduled',
              '${DateFormat('MMM dd, yyyy').format(preferredDate)} at $preferredTime',
              Icons.calendar_today,
              Colors.purple,
              isCompleted: false,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSpecificDetailsCard() {
    final serviceDetails = bookingData['serviceDetails'] as Map<String, dynamic>?;
    if (serviceDetails == null || serviceDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Service Specific Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...serviceDetails.entries.map((entry) {
              if (entry.value != null && entry.value.toString().isNotEmpty) {
                return _buildDetailRow(
                  _formatFieldName(entry.key),
                  entry.value.toString(),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotesCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Important Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNoteItem('Our admin will review and confirm your booking within 30 minutes'),
            _buildNoteItem('You will receive notifications about booking status updates'),
            _buildNoteItem('A qualified technician will be assigned to your service'),
            _buildNoteItem('Please ensure someone is available at the scheduled time'),
            _buildNoteItem('Payment will be collected after service completion'),
            _buildNoteItem('You can track your booking status in the app'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user-booking-status',
                (route) => route.settings.name == '/home',
              );
            },
            icon: const Icon(Icons.track_changes),
            label: const Text(
              'Track Booking Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text(
              'Back to Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.deepPurple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isCompleted = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? color : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : color,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
                height: 1.4,
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

  String _getPaymentMethodDisplay(String paymentMethod) {
    switch (paymentMethod) {
      case 'cash_on_service':
        return 'Cash on Service';
      case 'cash_on_hand':
        return 'Cash in Hand';
      case 'online':
        return 'Online Payment';
      default:
        return paymentMethod;
    }
  }

  String _formatFieldName(String fieldName) {
    // Convert camelCase to readable format
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }
}