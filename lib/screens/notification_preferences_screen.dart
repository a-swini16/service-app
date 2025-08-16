import 'package:flutter/material.dart';
import '../services/onesignal_service.dart';
import '../widgets/custom_app_bar.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final OneSignalService _messagingService = OneSignalService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Preference values
  bool _pushNotifications = true;
  bool _bookingUpdates = true;
  bool _paymentReminders = true;
  bool _promotionalOffers = false;
  bool _systemUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _messagingService.getNotificationPreferences();
      
      if (preferences != null) {
        setState(() {
          _pushNotifications = preferences['pushNotifications'] ?? true;
          _bookingUpdates = preferences['bookingUpdates'] ?? true;
          _paymentReminders = preferences['paymentReminders'] ?? true;
          _promotionalOffers = preferences['promotionalOffers'] ?? false;
          _systemUpdates = preferences['systemUpdates'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final preferences = {
        'pushNotifications': _pushNotifications,
        'bookingUpdates': _bookingUpdates,
        'paymentReminders': _paymentReminders,
        'promotionalOffers': _promotionalOffers,
        'systemUpdates': _systemUpdates,
      };

      final success = await _messagingService.updateNotificationPreferences(preferences);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to save preferences');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Notification Preferences',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Notification Settings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customize which notifications you want to receive',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Master toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        'Enable or disable all push notifications',
                      ),
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                          if (!value) {
                            // Disable all other notifications if master is disabled
                            _bookingUpdates = false;
                            _paymentReminders = false;
                            _promotionalOffers = false;
                            _systemUpdates = false;
                          }
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        _pushNotifications 
                            ? Icons.notifications_active 
                            : Icons.notifications_off,
                        color: _pushNotifications 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Individual notification types
                  const Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Booking Updates
                  Card(
                    child: SwitchListTile(
                      title: const Text('Booking Updates'),
                      subtitle: const Text(
                        'Status changes, worker assignments, service completion',
                      ),
                      value: _bookingUpdates && _pushNotifications,
                      onChanged: _pushNotifications ? (value) {
                        setState(() {
                          _bookingUpdates = value;
                        });
                      } : null,
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        Icons.assignment_outlined,
                        color: (_bookingUpdates && _pushNotifications) 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  
                  // Payment Reminders
                  Card(
                    child: SwitchListTile(
                      title: const Text('Payment Reminders'),
                      subtitle: const Text(
                        'Payment due notifications and confirmations',
                      ),
                      value: _paymentReminders && _pushNotifications,
                      onChanged: _pushNotifications ? (value) {
                        setState(() {
                          _paymentReminders = value;
                        });
                      } : null,
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        Icons.payment_outlined,
                        color: (_paymentReminders && _pushNotifications) 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  
                  // System Updates
                  Card(
                    child: SwitchListTile(
                      title: const Text('System Updates'),
                      subtitle: const Text(
                        'App updates, maintenance notifications',
                      ),
                      value: _systemUpdates && _pushNotifications,
                      onChanged: _pushNotifications ? (value) {
                        setState(() {
                          _systemUpdates = value;
                        });
                      } : null,
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        Icons.system_update_outlined,
                        color: (_systemUpdates && _pushNotifications) 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  
                  // Promotional Offers
                  Card(
                    child: SwitchListTile(
                      title: const Text('Promotional Offers'),
                      subtitle: const Text(
                        'Special deals, discounts, and marketing messages',
                      ),
                      value: _promotionalOffers && _pushNotifications,
                      onChanged: _pushNotifications ? (value) {
                        setState(() {
                          _promotionalOffers = value;
                        });
                      } : null,
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        Icons.local_offer_outlined,
                        color: (_promotionalOffers && _pushNotifications) 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional info
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• You can change these settings anytime\n'
                            '• Critical notifications may still be sent for security\n'
                            '• Some notifications may also appear in the app',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePreferences,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}