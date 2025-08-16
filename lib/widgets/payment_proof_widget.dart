import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class PaymentProofWidget extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onVerificationChanged;

  const PaymentProofWidget({
    Key? key,
    required this.booking,
    this.onVerificationChanged,
  }) : super(key: key);

  @override
  State<PaymentProofWidget> createState() => _PaymentProofWidgetState();
}

class _PaymentProofWidgetState extends State<PaymentProofWidget> {
  bool _isVerifying = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPaymentProof = widget.booking.paymentProof != null;
    
    if (!hasPaymentProof) {
      return const SizedBox.shrink();
    }

    final paymentProof = widget.booking.paymentProof!;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Payment Proof',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(paymentProof['status'] ?? 'pending_verification'),
              ],
            ),
            const SizedBox(height: 12),
            
            // Payment Details
            _buildDetailRow('Amount', '₹${paymentProof['amount']?.toInt() ?? 0}'),
            if (paymentProof['transactionId'] != null)
              _buildDetailRow('Transaction ID', paymentProof['transactionId']),
            _buildDetailRow(
              'Uploaded At', 
              _formatDateTime(paymentProof['uploadedAt'])
            ),
            
            const SizedBox(height: 16),
            
            // Payment Screenshot
            if (paymentProof['filename'] != null) ...[
              const Text(
                'Payment Screenshot:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, paymentProof['filename']),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: 'http://192.168.1.100:3000/api/payment/proof/${paymentProof['filename']}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 32),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to view full size',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Admin Notes (if any)
            if (paymentProof['adminNotes'] != null) ...[
              _buildDetailRow('Admin Notes', paymentProof['adminNotes']),
              const SizedBox(height: 16),
            ],
            
            // Verification Actions (only if pending)
            if (paymentProof['status'] == 'pending_verification') ...[
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Verification Actions:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Admin Notes (Optional)',
                  hintText: 'Add verification notes...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isVerifying ? null : () => _verifyPayment(true),
                      icon: const Icon(Icons.check_circle),
                      label: Text(_isVerifying ? 'Verifying...' : 'Verify Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isVerifying ? null : () => _verifyPayment(false),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'verified':
        color = Colors.green;
        label = 'Verified';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'pending_verification':
      default:
        color = Colors.orange;
        label = 'Pending';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return 'Invalid date';
      }
      
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showFullScreenImage(BuildContext context, String filename) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: 'http://192.168.1.100:3000/api/payment/proof/$filename',
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPayment(bool verified) async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await ApiService.post(
        '/payment/verify/${widget.booking.id}',
        {
          'verified': verified,
          'adminNotes': _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verified 
                    ? 'Payment verified successfully!' 
                    : 'Payment rejected successfully!',
              ),
              backgroundColor: verified ? Colors.green : Colors.orange,
            ),
          );
          
          // Notify parent widget to refresh
          widget.onVerificationChanged?.call();
        }
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
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
          _isVerifying = false;
        });
      }
    }
  }
}