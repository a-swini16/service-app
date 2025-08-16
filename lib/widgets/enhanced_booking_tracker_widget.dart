import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';

class EnhancedBookingTrackerWidget extends StatefulWidget {
  final String? bookingId;
  
  const EnhancedBookingTrackerWidget({Key? key, this.bookingId}) : super(key: key);

  @override
  State<EnhancedBookingTrackerWidget> createState() => _EnhancedBookingTrackerWidgetState();
}

class _EnhancedBookingTrackerWidgetState extends State<EnhancedBookingTrackerWidget> {
  bool _isLoading = false;
  String? _error;
  BookingModel? _specificBooking;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      // Check if user is authenticated
      if (!authProvider.isLoggedIn || authProvider.user == null) {
        throw Exception('Please login to view your bookings');
      }
      
      // Fetch user's bookings
      await bookingProvider.fetchUserBookings();
      
      debugPrint('✅ User bookings loaded: ${bookingProvider.bookings.length}');
      
      // If specific booking ID is provided, find it
      if (widget.bookingId != null) {
        _specificBooking = bookingProvider.bookings.firstWhere(
          (booking) => booking.id == widget.bookingId,
          orElse: () => throw Exception('Booking not found with ID: ${widget.bookingId}'),
        );
        debugPrint('✅ Found specific booking: ${_specificBooking!.customerName}');
      }
      
    } catch (e) {
      debugPrint('❌ Error loading bookings: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your bookings...'),
              ],
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadBookings,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final bookings = bookingProvider.bookings;
        
        // If specific booking ID is provided, show only that booking
        if (widget.bookingId != null) {
          if (_specificBooking == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Booking not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Booking ID: ${widget.bookingId}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadBookings,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: _buildEnhancedBookingCard(_specificBooking!),
            ),
          );
        }
        
        // Show all bookings
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_online, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No bookings found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new booking to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/booking-form');
                  },
                  icon: Icon(Icons.add),
                  label: Text('Create Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadBookings,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildEnhancedBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with service name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceDisplayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${booking.id.substring(booking.id.length - 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Customer Details Section
            _buildSectionHeader('Customer Details', Icons.person),
            SizedBox(height: 8),
            _buildDetailRow('Name', booking.customerName),
            _buildDetailRow('Phone', booking.customerPhone),
            _buildDetailRow('Address', booking.customerAddress),
            if (booking.description?.isNotEmpty == true)
              _buildDetailRow('Description', booking.description!),
            
            SizedBox(height: 16),

            // Service Details Section
            _buildSectionHeader('Service Details', Icons.build),
            SizedBox(height: 8),
            _buildDetailRow('Service Type', booking.serviceDisplayName),
            _buildDetailRow('Preferred Date', 
                '${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year}'),
            _buildDetailRow('Preferred Time', booking.preferredTime),
            _buildDetailRow('Payment Method', booking.paymentMethodDisplayName),
            if (booking.paymentAmount != null)
              _buildDetailRow('Amount', '₹${booking.paymentAmount}'),
            
            // Worker Assignment Section
            if (booking.assignedEmployeeName != null) ...[
              SizedBox(height: 16),
              _buildSectionHeader('Assigned Worker', Icons.engineering),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name', booking.assignedEmployeeName!),
                    if (booking.assignedEmployeePhone != null)
                      _buildDetailRow('Phone', booking.assignedEmployeePhone!),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16),

            // Progress Section
            _buildSectionHeader('Progress', Icons.timeline),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(booking.progressPercentage * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                    Text(
                      booking.nextExpectedAction,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: booking.progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(booking.status),
                  ),
                ),
              ],
            ),

            // Status History Section
            if (booking.statusHistory.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildSectionHeader('Status History', Icons.history),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: booking.statusHistory.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.statusDisplayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (entry.notes?.isNotEmpty == true)
                                  Text(
                                    entry.notes!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Action Buttons
            SizedBox(height: 16),
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.deepPurple),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
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
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    // Payment button for completed bookings
    if (booking.status == 'completed' && !booking.isPaid) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/payment',
                arguments: booking.id,
              );
            },
            icon: Icon(Icons.payment),
            label: Text('Make Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // Contact worker button
    if (booking.assignedEmployeePhone != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Implement call functionality
              _showContactWorkerDialog(booking);
            },
            icon: Icon(Icons.phone),
            label: Text('Contact Worker'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // View details button
    buttons.add(
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/booking-details',
              arguments: booking.id,
            );
          },
          icon: Icon(Icons.info),
          label: Text('View Full Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );

    return Column(
      children: buttons.map((button) => Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: button,
      )).toList(),
    );
  }

  void _showContactWorkerDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Worker: ${booking.assignedEmployeeName}'),
            Text('Phone: ${booking.assignedEmployeePhone}'),
            SizedBox(height: 16),
            Text('How would you like to contact the worker?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${booking.assignedEmployeeName}...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Call Now'),
          ),
        ],
      ),
    );
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
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}