import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/service_model.dart';
import '../constants/app_constants.dart';
import '../widgets/service_specific_form.dart';
import '../services/api_service.dart';
import 'booking_confirmation_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final String? serviceType;
  
  const BookingFormScreen({Key? key, this.serviceType}) : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GlobalKey<FormState> _serviceFormKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedTime;
  String _paymentMethod = AppConstants.cashOnService;
  ServiceModel? _service;
  Map<String, dynamic> _serviceSpecificData = {};
  Map<String, String> _validationErrors = {};
  bool _isValidating = false;
  Map<String, String> Function()? _serviceFormValidator;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        _nameController.text = authProvider.user!.name;
        _phoneController.text = authProvider.user!.phone;
        _addressController.text = authProvider.user!.address;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    
    print('BookingForm - Args: $args');
    print('BookingForm - Widget serviceType: ${widget.serviceType}');
    
    if (args is ServiceModel) {
      _service = args;
      print('BookingForm - Service from args: ${_service?.name}');
    } else if (args is Map<String, dynamic> && args['serviceType'] != null) {
      // Handle serviceType from route arguments
      final serviceType = args['serviceType'] as String;
      _service = _getServiceByType(serviceType);
      print('BookingForm - Service from map: ${_service?.name}');
    } else if (widget.serviceType != null) {
      // Handle serviceType from constructor
      _service = _getServiceByType(widget.serviceType!);
      print('BookingForm - Service from widget: ${_service?.name}');
    } else {
      // Default to water purifier if no service specified
      _service = _getServiceByType('water_purifier');
      print('BookingForm - Default service: ${_service?.name}');
    }
  }

  ServiceModel? _getServiceByType(String serviceType) {
    // Create a default service model based on serviceType
    switch (serviceType) {
      case 'water_purifier':
        return ServiceModel(
          basePrice: 0, // Default base price, will be determined by admin later
          id: '1',
          name: 'water_purifier',
          displayName: 'Water Purifier Service',
          description: 'Complete water purifier maintenance and repair service',
          // Price will be determined by admin after service completion
          duration: 60,
          category: 'Home Appliances',
        );
      case 'ac_repair':
        return ServiceModel(
          basePrice: 0, // Default base price, will be determined by admin later
          id: '2',
          name: 'ac_repair',
          displayName: 'AC Repair Service',
          description: 'Professional AC repair and maintenance service',
          // Price will be determined by admin after service completion
          duration: 90,
          category: 'Home Appliances',
        );
      case 'refrigerator_repair':
        return ServiceModel(
          basePrice: 0, // Default base price, will be determined by admin later
          id: '3',
          name: 'refrigerator_repair',
          displayName: 'Refrigerator Repair Service',
          description: 'Expert refrigerator repair and maintenance service',
          // Price will be determined by admin after service completion
          duration: 75,
          category: 'Home Appliances',
        );
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _validationErrors.remove('date');
      });
    }
  }

  bool _validateForm() {
    setState(() {
      _isValidating = true;
      _validationErrors.clear();
    });

    bool isValid = true;

    // Validate basic form
    if (!_formKey.currentState!.validate()) {
      isValid = false;
    }

    // Validate date and time
    if (_selectedDate == null) {
      _validationErrors['date'] = 'Please select a preferred date';
      isValid = false;
    }

    if (_selectedTime == null) {
      _validationErrors['time'] = 'Please select a preferred time';
      isValid = false;
    }

    // Validate service-specific fields
    if (_serviceFormValidator != null) {
      final serviceErrors = _serviceFormValidator!();
      if (serviceErrors.isNotEmpty) {
        _validationErrors.addAll(serviceErrors);
        isValid = false;
      }
    }

    setState(() {
      _isValidating = false;
    });

    return isValid;
  }

  // Helper method to convert 12-hour time format to 24-hour format
  String _convertTo24HourFormat(String time12h) {
    // Parse the time in 12-hour format
    final parts = time12h.split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    final minutes = timeParts[1];
    final period = parts[1]; // AM or PM
    
    // Convert to 24-hour format
    if (period == 'PM' && hours < 12) {
      hours += 12;
    } else if (period == 'AM' && hours == 12) {
      hours = 0;
    }
    
    // Format as HH:MM
    return '${hours.toString().padLeft(2, '0')}:$minutes';
  }

  Future<void> _submitBooking() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service information is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    // Convert time from 12-hour to 24-hour format
    final preferredTime24h = _convertTo24HourFormat(_selectedTime!);

    // Set default payment method to cash on service since we removed the payment method selection
    _paymentMethod = AppConstants.cashOnService;

    final bookingData = {
      'serviceType': _service!.name,
      'customerName': _nameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'customerAddress': _addressController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'preferredDate': _selectedDate!.toIso8601String(),
      'preferredTime': preferredTime24h, // Use the converted 24-hour format
      'paymentMethod': _paymentMethod,
      'paymentAmount': _service!.basePrice,
      'serviceDetails': _serviceSpecificData,
    };

    final result = await ApiService.createBooking(bookingData);

    if (!mounted) return;

    if (result['success']) {
      // Navigate to confirmation screen instead of payment
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            bookingData: bookingData,
            service: _service!,
            bookingId: result['booking']?['_id'] ?? 'Unknown',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Booking failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info Card
              if (_service != null)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getServiceIcon(_service!.name),
                          size: 40,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _service!.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '₹${_service!.basePrice.toInt()} • ${_service!.duration} minutes',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),

              // Customer Information
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Service Address *',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Enter complete address where service is required',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Preferred Date & Time
              Text(
                'Preferred Date & Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _validationErrors.containsKey('date')
                          ? Colors.red
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                            : 'Select Date *',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              if (_validationErrors.containsKey('date'))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validationErrors['date']!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Time Selection
              Text(
                'Select Time Slot *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _validationErrors.containsKey('time')
                      ? Colors.red
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((time) {
                  final isSelected = _selectedTime == time;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                        _validationErrors.remove('time');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.deepPurple : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_validationErrors.containsKey('time'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _validationErrors['time']!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Service-Specific Form
              if (_service != null)
                ServiceSpecificForm(
                  service: _service!,
                  formData: _serviceSpecificData,
                  onFormDataChanged: (data) {
                    setState(() {
                      _serviceSpecificData = data;
                    });
                  },
                  onValidationCallback: (validator) {
                    _serviceFormValidator = validator;
                  },
                ),
              const SizedBox(height: 20),

              // Problem Description
              Text(
                'Problem Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Describe the issue (Optional)',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Please describe the problem you are facing...',
                ),
              ),
              SizedBox(height: 20),

              // Payment method section removed as requested
              SizedBox(height: 20),

              // Terms and Conditions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Service charges are subject to actual work done'),
                    Text(
                        '• Additional charges may apply for parts replacement'),
                    Text(
                        '• Technician will arrive within the selected time slot'),
                    Text('• Payment can be made after service completion'),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Book Now Button
              SizedBox(
                width: double.infinity,
                child: Consumer<BookingProvider>(
                  builder: (context, bookingProvider, child) {
                    return ElevatedButton(
                      onPressed: (bookingProvider.isLoading || _isValidating)
                          ? null
                          : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: bookingProvider.isLoading || _isValidating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
}
