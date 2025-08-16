import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';

class BookingTrackerWidget extends StatefulWidget {
  final String? bookingId;
  
  const BookingTrackerWidget({Key? key, this.bookingId}) : super(key: key);

  @override
  State<BookingTrackerWidget> createState() => _BookingTrackerWidgetState();
}

class _BookingTrackerWidgetState extends State<BookingTrackerWidget> {
  bool _isLoading = false;
  String? _error;

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
      // Ensure user is logged in
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        print('🔐 User not logged in, attempting login...');
        final loginResult = await authProvider.login(
          email: 'testuser@example.com',
          password: 'password123',
        );
        if (loginResult['success'] != true) {
          throw Exception('Login failed: ${loginResult['message']}');
        }
      }

      // Fetch bookings
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.fetchUserBookings();
      
      print('✅ Bookings loaded: ${bookingProvider.bookings.length}');
    } catch (e) {
      print('❌ Error loading bookings: $e');
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

        // Filter to specific booking if bookingId is provided
        List<BookingModel> displayBookings = bookings;
        if (widget.bookingId != null) {
          displayBookings = bookings.where((b) => b.id == widget.bookingId).toList();
          if (displayBookings.isEmpty) {
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
        }

        return RefreshIndicator(
          onRefresh: _loadBookings,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: displayBookings.length,
            itemBuilder: (context, index) {
              final booking = displayBookings[index];
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        ),
                      ),
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

            // Details
            _buildDetailRow('Customer', booking.customerName),
            _buildDetailRow('Phone', booking.customerPhone),
            _buildDetailRow('Address', booking.customerAddress),
            if (booking.description?.isNotEmpty == true)
              _buildDetailRow('Description', booking.description!),
            _buildDetailRow('Preferred Date', 
                '${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year}'),
            _buildDetailRow('Preferred Time', booking.preferredTime),
            _buildDetailRow('Payment Method', booking.paymentMethodDisplayName),
            if (booking.paymentAmount != null)
              _buildDetailRow('Amount', '₹${booking.paymentAmount}'),
            
            // Worker info
            if (booking.assignedEmployeeName != null) ...[
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
                    Text(
                      'Assigned Worker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Name: ${booking.assignedEmployeeName}'),
                    if (booking.assignedEmployeePhone != null)
                      Text('Phone: ${booking.assignedEmployeePhone}'),
                  ],
                ),
              ),
            ],

            // Progress indicator
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: booking.progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(booking.status),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  booking.nextExpectedAction,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Action buttons
            if (booking.status == 'completed' && !booking.isPaid) ...[
              SizedBox(height: 16),
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
              ),
            ),
          ),
          Expanded(
            child: Text(value),
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