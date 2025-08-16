import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';

class RefrigeratorServiceScreen extends StatelessWidget {
  final ServiceModel service = ServiceModel(
    id: '3',
    name: 'refrigerator_service',
    displayName: 'Refrigerator Service & Repair',
    description:
        'Professional refrigerator repair, maintenance, and installation services',
    basePrice: 600.0,
    duration: 75,
    category: 'Home Appliances',
  );

  // Contact Information
  static const String contactPhoneNumber = '+91 94393 46257';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refrigerator Repair Service'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[100]!, Colors.indigo[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.kitchen,
                  size: 80,
                  color: Colors.indigo[800],
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

                  // Common Issues
                  Text(
                    'Common Issues We Fix',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildIssueItem('Not cooling properly', Icons.thermostat),
                  _buildIssueItem('Strange noises', Icons.volume_up),
                  _buildIssueItem('Water leakage', Icons.water_drop),
                  _buildIssueItem('Door not closing', Icons.door_front_door),
                  _buildIssueItem('Ice maker problems', Icons.ac_unit),
                  _buildIssueItem('Electrical issues', Icons.electrical_services),
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
                  _buildServiceItem('Complete diagnostic check'),
                  _buildServiceItem('Compressor inspection'),
                  _buildServiceItem('Thermostat calibration'),
                  _buildServiceItem('Door seal replacement'),
                  _buildServiceItem('Coil cleaning'),
                  _buildServiceItem('Gas refill if needed'),
                  _buildServiceItem('Performance testing'),
                  SizedBox(height: 20),

                  // Refrigerator Types
                  Text(
                    'Refrigerator Types We Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRefrigeratorTypeCard(
                            'Single Door', Icons.door_front_door),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildRefrigeratorTypeCard(
                            'Double Door', Icons.door_back_door),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRefrigeratorTypeCard(
                            'Side by Side', Icons.view_column),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildRefrigeratorTypeCard(
                            'French Door', Icons.kitchen),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Features
                  Text(
                    'Why Choose Us?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildFeatureItem(Icons.verified, 'Expert Technicians'),
                  _buildFeatureItem(Icons.schedule, 'Quick Response'),
                  _buildFeatureItem(Icons.security, '6 Month Warranty'),
                  _buildFeatureItem(Icons.support_agent, '24/7 Support'),
                  _buildFeatureItem(Icons.price_check, 'Fair Pricing'),
                  _buildFeatureItem(Icons.build, 'Genuine Parts'),
                  SizedBox(height: 30),

                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/booking-form',
                          arguments: service,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book Service Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Call Now Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _launchPhoneCall();
                      },
                      icon: Icon(Icons.phone),
                      label: Text(
                        'Call Now for Urgent Repair',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildIssueItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.red[600],
              size: 18,
            ),
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

  Widget _buildRefrigeratorTypeCard(String title, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.indigo[600],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Future<void> _launchPhoneCall() async {
    try {
      // Clean the phone number - remove spaces and ensure proper format
      final String cleanPhoneNumber = contactPhoneNumber.replaceAll(' ', '');
      
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
        } else {
          print('❌ Failed to launch phone dialer');
        }
      } else {
        print('❌ Cannot launch phone dialer');
      }
    } catch (e) {
      print('❌ Error making phone call: $e');
    }
  }
}
