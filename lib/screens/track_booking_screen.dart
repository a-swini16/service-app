import 'package:flutter/material.dart';
import '../widgets/enhanced_booking_tracker_widget.dart';

class TrackBookingScreen extends StatelessWidget {
  final String? bookingId;

  const TrackBookingScreen({Key? key, this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get booking ID from route arguments if not provided
    final String? routeBookingId = ModalRoute.of(context)?.settings.arguments as String?;
    final String? finalBookingId = bookingId ?? routeBookingId;

    return Scaffold(
      appBar: AppBar(
        title: Text(finalBookingId != null ? 'Track Booking' : 'My Bookings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Trigger refresh by rebuilding the widget
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackBookingScreen(bookingId: finalBookingId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: EnhancedBookingTrackerWidget(bookingId: finalBookingId),
    );
  }
}