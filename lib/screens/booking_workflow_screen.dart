import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/notification_provider.dart';
import '../constants/app_constants.dart';

class BookingWorkflowScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingWorkflowScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  State<BookingWorkflowScreen> createState() => _BookingWorkflowScreenState();
}

class _BookingWorkflowScreenState extends State<BookingWorkflowScreen> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.booking.paymentAmount?.toString() ?? '0';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _acceptBooking() async {
    setState(() {
      _isProcessing = true;
    });

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.acceptBooking(
      widget.booking.id,
      adminNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to accept booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectBooking() async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.rejectBooking(
      widget.booking.id,
      _rejectionReasonController.text.trim(),
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking rejected successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignWorker() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final workers = await bookingProvider.getAvailableWorkers(
        serviceType: widget.booking.serviceType);

    if (!mounted) return;

    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available workers for this service type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Worker'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(worker['name'][0]),
                ),
                title: Text(worker['name']),
                subtitle: Text('Rating: ${worker['rating']} ⭐'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _assignWorkerToBooking(worker['_id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignWorkerToBooking(String workerId) async {
    setState(() {
      _isProcessing = true;
    });

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result =
        await bookingProvider.assignWorker(widget.booking.id, workerId);

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker assigned successfully!'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to assign worker'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startWork() async {
    setState(() {
      _isProcessing = true;
    });

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.startWork(
      widget.booking.id,
      workerNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to start service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeWork() async {
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

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.completeWork(
      widget.booking.id,
      workerNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      actualAmount: amount,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to complete service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
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

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.completePayment(
      widget.booking.id,
      amount,
      widget.booking.paymentMethod,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to process payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.booking.serviceDisplayName} - Workflow'),
        backgroundColor: _getStatusColor(widget.booking.status),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 24),

            // Booking Details Card
            _buildBookingDetailsCard(),
            const SizedBox(height: 24),

            // Action Section based on current status
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {
        'status': 'pending',
        'title': 'Booking Created',
        'icon': Icons.create,
        'description': 'Waiting for admin review'
      },
      {
        'status': 'accepted',
        'title': 'Admin Accepted',
        'icon': Icons.check_circle,
        'description': 'Booking approved'
      },
      {
        'status': 'assigned',
        'title': 'Worker Assigned',
        'icon': Icons.person,
        'description': 'Worker allocated'
      },
      {
        'status': 'in_progress',
        'title': 'Service Started',
        'icon': Icons.build,
        'description': 'Work in progress'
      },
      {
        'status': 'completed',
        'title': 'Service Completed',
        'icon': Icons.done_all,
        'description': 'Work finished'
      },
      {
        'status': 'paid',
        'title': 'Payment Done',
        'icon': Icons.payment,
        'description': 'Payment received'
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((statusInfo) {
              final isCompleted =
                  _isStatusCompleted(statusInfo['status'] as String);
              final isCurrent = widget.booking.status == statusInfo['status'] ||
                  (statusInfo['status'] == 'paid' && widget.booking.isPaid);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? Colors.green
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusInfo['icon'] as IconData,
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusInfo['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCompleted || isCurrent
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            statusInfo['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'Current Step',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCompleted || isCurrent)
                      Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Service', widget.booking.serviceDisplayName),
            _buildDetailRow('Customer', widget.booking.customerName),
            _buildDetailRow('Phone', widget.booking.customerPhone),
            _buildDetailRow('Address', widget.booking.customerAddress),
            _buildDetailRow(
              'Preferred Date',
              DateFormat('dd MMM yyyy').format(widget.booking.preferredDate),
            ),
            _buildDetailRow('Preferred Time', widget.booking.preferredTime),
            if (widget.booking.description?.isNotEmpty == true)
              _buildDetailRow('Description', widget.booking.description!),
            if (widget.booking.assignedEmployeeName != null)
              _buildDetailRow(
                  'Assigned Worker', widget.booking.assignedEmployeeName!),
            _buildDetailRow('Status', widget.booking.statusDisplayName),
            _buildDetailRow(
                'Payment Method', widget.booking.paymentMethodDisplayName),
            _buildDetailRow(
                'Amount', '₹${widget.booking.paymentAmount?.toInt() ?? 0}'),
            if (widget.booking.actualAmount != null)
              _buildDetailRow(
                  'Actual Amount', '₹${widget.booking.actualAmount!.toInt()}'),
            if (widget.booking.adminNotes?.isNotEmpty == true)
              _buildDetailRow('Admin Notes', widget.booking.adminNotes!),
            if (widget.booking.workerNotes?.isNotEmpty == true)
              _buildDetailRow('Worker Notes', widget.booking.workerNotes!),
            if (widget.booking.rejectionReason?.isNotEmpty == true)
              _buildDetailRow(
                  'Rejection Reason', widget.booking.rejectionReason!),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    switch (widget.booking.status) {
      case 'pending':
        return _buildPendingActions();
      case 'accepted':
        return _buildAssignWorkerSection();
      case 'assigned':
        return _buildStartWorkSection();
      case 'in_progress':
        return _buildCompleteWorkSection();
      case 'completed':
        if (!widget.booking.isPaid) {
          return _buildPaymentSection();
        }
        return _buildCompletedSection();
      case 'rejected':
        return _buildRejectedSection();
      default:
        return _buildInfoSection();
    }
  }

  Widget _buildPendingActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                hintText: 'Add any notes about this booking...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _acceptBooking,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _showRejectDialog,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildAssignWorkerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Worker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Booking has been accepted. Now assign a worker to start the service.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _assignWorker,
                icon: const Icon(Icons.person_add),
                label: const Text('Assign Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartWorkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Work Notes (Optional)',
                hintText: 'Add any notes about starting the service...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _startWork,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          Text('Starting Service...'),
                        ],
                      )
                    : const Text(
                        'Start Service',
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
    );
  }

  Widget _buildCompleteWorkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Final Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                helperText: 'Enter the actual service amount',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Work Completion Notes (Optional)',
                hintText: 'Add notes about the completed work...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completeWork,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          Text('Completing Service...'),
                        ],
                      )
                    : const Text(
                        'Complete Service',
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
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Process Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Service has been completed successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                helperText: 'Confirm the payment amount received',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          Text('Processing Payment...'),
                        ],
                      )
                    : const Text(
                        'Confirm Payment Received',
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
    );
  }

  Widget _buildCompletedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
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
            const Text(
              'Payment has been processed and the service is complete.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Rejected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (widget.booking.rejectionReason?.isNotEmpty == true)
              Text(
                'Reason: ${widget.booking.rejectionReason}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.info,
              color: Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Status: ${widget.booking.statusDisplayName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'No actions available at this time.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject booking for ${widget.booking.customerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectBooking();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
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

  bool _isStatusCompleted(String status) {
    const statusOrder = [
      'pending',
      'accepted',
      'assigned',
      'in_progress',
      'completed',
      'paid'
    ];

    final currentIndex = statusOrder.indexOf(widget.booking.status);
    final checkIndex = statusOrder.indexOf(status);

    if (status == 'paid') {
      return widget.booking.isPaid;
    }

    return checkIndex <= currentIndex;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
