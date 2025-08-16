import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../constants/app_constants.dart';
import 'dart:ui';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({Key? key}) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  String? bookingId;
  BookingModel? booking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      bookingId = args;
      _findBooking();
    }
  }

  void _findBooking() {
    if (bookingId != null) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final allBookings = [
        ...bookingProvider.bookings,
        ...bookingProvider.adminBookings
      ];

      try {
        booking = allBookings.firstWhere((b) => b.id == bookingId);
        setState(() {});
      } catch (e) {
        // Booking not found in local cache, could fetch from API
        print('Booking not found: $bookingId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Booking not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Booking Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking!.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booking!.statusDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusTimeline(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                    Row(
                      children: [
                        Icon(
                          _getServiceIcon(booking!.serviceType),
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking!.serviceDisplayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Booking ID: ${booking!.id.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Customer', booking!.customerName),
                    _buildDetailRow('Phone', booking!.customerPhone),
                    _buildDetailRow('Address', booking!.customerAddress),
                    _buildDetailRow(
                      'Preferred Date',
                      DateFormat('dd MMM yyyy').format(booking!.preferredDate),
                    ),
                    _buildDetailRow('Preferred Time', booking!.preferredTime),
                    if (booking!.description?.isNotEmpty == true)
                      _buildDetailRow('Description', booking!.description!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Worker Details (if assigned)
            if (booking!.assignedEmployeeName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Technician',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking!.assignedEmployeeName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (booking!.assignedEmployeePhone != null)
                                  Text(
                                    booking!.assignedEmployeePhone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (booking!.assignedEmployeePhone != null)
                            IconButton(
                              onPressed: () async {
                                final String phoneNumber =
                                    booking!.assignedEmployeePhone!;
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: phoneNumber,
                                );

                                try {
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Could not launch phone dialer'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon:
                                  const Icon(Icons.phone, color: Colors.green),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Details Card
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
                    _buildDetailRow(
                        'Payment Method', booking!.paymentMethodDisplayName),
                    _buildDetailRow(
                      'Estimated Amount',
                      '₹${booking!.paymentAmount?.toInt() ?? 0}',
                    ),
                    if (booking!.actualAmount != null)
                      _buildDetailRow(
                        'Final Amount',
                        '₹${booking!.actualAmount!.toInt()}',
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Status:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                booking!.isPaid ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking!.isPaid ? 'PAID' : 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Section
            if (booking!.adminNotes?.isNotEmpty == true ||
                booking!.workerNotes?.isNotEmpty == true ||
                booking!.rejectionReason?.isNotEmpty == true) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (booking!.adminNotes?.isNotEmpty == true)
                        _buildNoteSection('Admin Notes', booking!.adminNotes!),
                      if (booking!.workerNotes?.isNotEmpty == true)
                        _buildNoteSection(
                            'Worker Notes', booking!.workerNotes!),
                      if (booking!.rejectionReason?.isNotEmpty == true)
                        _buildNoteSection(
                            'Rejection Reason', booking!.rejectionReason!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (booking!.status == AppConstants.completed &&
                !booking!.isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/payment',
                      arguments: {
                        'booking': booking,
                        'isPostService': true,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Complete Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildStatusTimeline() {
    final statuses = [
      {
        'status': AppConstants.pending,
        'label': 'Booking Submitted',
        'date': booking!.createdAt
      },
      if (booking!.acceptedDate != null)
        {
          'status': AppConstants.accepted,
          'label': 'Accepted by Admin',
          'date': booking!.acceptedDate
        },
      if (booking!.rejectedDate != null)
        {
          'status': AppConstants.rejected,
          'label': 'Rejected',
          'date': booking!.rejectedDate
        },
      if (booking!.assignedDate != null)
        {
          'status': AppConstants.assigned,
          'label': 'Worker Assigned',
          'date': booking!.assignedDate
        },
      if (booking!.completedDate != null)
        {
          'status': AppConstants.completed,
          'label': 'Service Completed',
          'date': booking!.completedDate
        },
    ];

    return Column(
      children: statuses.map((statusInfo) {
        final isActive = _isStatusActive(statusInfo['status'] as String);
        final date = statusInfo['date'] as DateTime?;

        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusInfo['label'] as String,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isStatusActive(String status) {
    final statusOrder = [
      AppConstants.pending,
      AppConstants.accepted,
      AppConstants.assigned,
      AppConstants.inProgress,
      AppConstants.completed,
    ];

    final currentIndex = statusOrder.indexOf(booking!.status);
    final checkIndex = statusOrder.indexOf(status);

    if (booking!.status == AppConstants.rejected) {
      return status == AppConstants.pending || status == AppConstants.rejected;
    }

    return checkIndex <= currentIndex;
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String title, String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            note,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.pending:
        return Colors.orange;
      case AppConstants.accepted:
        return Colors.blue;
      case AppConstants.rejected:
        return Colors.red;
      case AppConstants.assigned:
        return Colors.purple;
      case AppConstants.inProgress:
        return Colors.indigo;
      case AppConstants.completed:
        return Colors.green;
      case AppConstants.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
