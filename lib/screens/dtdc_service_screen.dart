import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';

class DTDCServiceScreen extends StatefulWidget {
  @override
  _DTDCServiceScreenState createState() => _DTDCServiceScreenState();
}

class _DTDCServiceScreenState extends State<DTDCServiceScreen> {
  final ServiceModel service = ServiceModel(
    id: '4',
    name: 'dtdc_courier',
    displayName: 'DTDC Courier Service',
    description:
        'Professional courier and logistics services for all your shipping needs',
    basePrice: 200.0,
    duration: 30,
    category: 'Logistics',
  );

  // DTDC Contact Information
  static const String dtdcPhoneNumber = '+91 94393 46257';
  static const String dtdcLocation = '22°05\'45.2"N 85°23\'02.8"E';

  Future<void> _makePhoneCall() async {
    try {
      // Clean the phone number - remove spaces and ensure proper format
      final String cleanPhoneNumber = dtdcPhoneNumber.replaceAll(' ', '');

      // Create URI for phone call
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: cleanPhoneNumber,
      );

      print('🔍 Attempting to call: $cleanPhoneNumber');
      print('🔍 URI: $launchUri');

      // Check if the URL can be launched
      if (await canLaunchUrl(launchUri)) {
        // Launch the phone dialer
        final bool launched = await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ Phone dialer launched successfully');
          _showSuccessSnackBar('Opening phone dialer for $cleanPhoneNumber');
        } else {
          print('❌ Failed to launch phone dialer');
          _showErrorSnackBar(context, 'Failed to open phone dialer');
        }
      } else {
        print('❌ Cannot launch phone dialer');
        _showErrorSnackBar(context, 'Phone dialer not available');
      }
    } catch (e) {
      print('❌ Error making phone call: $e');
      _showErrorSnackBar(context, 'Error: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    // Show success message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLocation() async {
    // Convert coordinates to decimal format for Google Maps
    // 22°05'45.2"N = 22.095889°N, 85°23'02.8"E = 85.384111°E
    const double latitude = 22.095889;
    const double longitude = 85.384111;

    final Uri launchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      print('Error opening location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DTDC Courier Service'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with DTDC Logo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple[100]!, Colors.deepPurple[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/dtdc.jpg',
                    height: 120,
                    width: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Title
                  Text(
                    service.displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Professional service • ${service.duration} minutes duration',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Description
                  Text(
                    'Service Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Services Included
                  Text(
                    'Services Included',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildServiceItem('Express Delivery'),
                  _buildServiceItem('Bulk Shipping'),
                  _buildServiceItem('Real-time Tracking'),
                  _buildServiceItem('Secure Packaging'),
                  _buildServiceItem('Cash on Delivery'),
                  _buildServiceItem('Door-to-Door Service'),
                  SizedBox(height: 20),

                  // Features
                  Text(
                    'Why Choose DTDC?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildFeatureItem(Icons.verified, 'Certified Service'),
                  _buildFeatureItem(Icons.schedule, 'Same Day Pickup'),
                  _buildFeatureItem(Icons.security, 'Secure Handling'),
                  _buildFeatureItem(Icons.support_agent, '24/7 Support'),
                  SizedBox(height: 30),

                  // Contact Information
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Phone Number Card
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Call Us',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        dtdcPhoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: _makePhoneCall,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Location Card
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Our Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        dtdcLocation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: _openLocation,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
