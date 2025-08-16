import 'package:flutter/material.dart';
import '../models/service_model.dart';

class ServiceSpecificForm extends StatefulWidget {
  final ServiceModel service;
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onFormDataChanged;
  final Function(Map<String, String> Function())? onValidationCallback;

  const ServiceSpecificForm({
    Key? key,
    required this.service,
    required this.formData,
    required this.onFormDataChanged,
    this.onValidationCallback,
  }) : super(key: key);

  @override
  State<ServiceSpecificForm> createState() => _ServiceSpecificFormState();
}

class _ServiceSpecificFormState extends State<ServiceSpecificForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _validationErrors = {};

  // Method to validate all fields - can be called from parent
  Map<String, String> validateAllFields() {
    final errors = <String, String>{};
    final fields = _getServiceSpecificFields();

    for (final field in fields) {
      final key = field['key'] as String;
      final value = widget.formData[key]?.toString();
      final error = _validateField(field, value);
      if (error != null) {
        errors[key] = error;
      }
    }

    setState(() {
      _validationErrors.clear();
      _validationErrors.addAll(errors);
    });

    return errors;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Pass the validation function to parent
    if (widget.onValidationCallback != null) {
      widget.onValidationCallback!(validateAllFields);
    }
  }

  void _initializeControllers() {
    final fields = _getServiceSpecificFields();
    for (final field in fields) {
      final key = field['key'] as String;
      _controllers[key] = TextEditingController(
        text: widget.formData[key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _getServiceSpecificFields() {
    switch (widget.service.name) {
      case 'water_purifier':
        return [
          {
            'key': 'purifierBrand',
            'label': 'Water Purifier Brand',
            'type': 'dropdown',
            'required': true,
            'options': [
              'Aquaguard',
              'Kent',
              'Pureit',
              'Livpure',
              'Blue Star',
              'Other'
            ],
            'hint': 'Select your water purifier brand',
          },
          {
            'key': 'purifierModel',
            'label': 'Model Number (Optional)',
            'type': 'text',
            'required': false,
            'hint': 'Enter model number if known',
          },
          {
            'key': 'lastServiceDate',
            'label': 'Last Service Date (Optional)',
            'type': 'date',
            'required': false,
            'hint': 'When was it last serviced?',
          },
          {
            'key': 'issueType',
            'label': 'Primary Issue',
            'type': 'dropdown',
            'required': true,
            'options': [
              'Water taste/smell issue',
              'Low water flow',
              'Filter replacement needed',
              'UV lamp not working',
              'Water leakage',
              'No power/electrical issue',
              'General maintenance',
              'Other'
            ],
            'hint': 'Select the main issue you\'re facing',
          },
          {
            'key': 'urgencyLevel',
            'label': 'Urgency Level',
            'type': 'radio',
            'required': true,
            'options': ['Normal', 'Urgent', 'Emergency'],
            'hint': 'How urgent is this repair?',
          },
        ];
      case 'ac_repair':
        return [
          {
            'key': 'acType',
            'label': 'AC Type',
            'type': 'dropdown',
            'required': true,
            'options': ['Window AC', 'Split AC', 'Central AC', 'Cassette AC'],
            'hint': 'Select your AC type',
          },
          {
            'key': 'acBrand',
            'label': 'AC Brand',
            'type': 'dropdown',
            'required': true,
            'options': [
              'LG',
              'Samsung',
              'Daikin',
              'Voltas',
              'Godrej',
              'Hitachi',
              'Blue Star',
              'Other'
            ],
            'hint': 'Select your AC brand',
          },
          {
            'key': 'acCapacity',
            'label': 'AC Capacity (Tons)',
            'type': 'dropdown',
            'required': true,
            'options': [
              '1 Ton',
              '1.5 Ton',
              '2 Ton',
              '2.5 Ton',
              '3 Ton',
              'Above 3 Ton'
            ],
            'hint': 'Select AC capacity',
          },
          {
            'key': 'installationYear',
            'label': 'Installation Year (Optional)',
            'type': 'number',
            'required': false,
            'hint': 'When was the AC installed?',
          },
          {
            'key': 'issueType',
            'label': 'Primary Issue',
            'type': 'dropdown',
            'required': true,
            'options': [
              'Not cooling properly',
              'Strange noises',
              'Water leakage',
              'Remote not working',
              'AC not turning on',
              'Gas refill needed',
              'Filter cleaning',
              'General service',
              'Other'
            ],
            'hint': 'Select the main issue',
          },
          {
            'key': 'roomSize',
            'label': 'Room Size (Sq Ft)',
            'type': 'number',
            'required': false,
            'hint': 'Approximate room size',
          },
        ];
      case 'refrigerator_repair':
        return [
          {
            'key': 'fridgeType',
            'label': 'Refrigerator Type',
            'type': 'dropdown',
            'required': true,
            'options': [
              'Single Door',
              'Double Door',
              'Side by Side',
              'French Door',
              'Mini Fridge'
            ],
            'hint': 'Select refrigerator type',
          },
          {
            'key': 'fridgeBrand',
            'label': 'Refrigerator Brand',
            'type': 'dropdown',
            'required': true,
            'options': [
              'LG',
              'Samsung',
              'Whirlpool',
              'Godrej',
              'Haier',
              'Bosch',
              'Other'
            ],
            'hint': 'Select your refrigerator brand',
          },
          {
            'key': 'capacity',
            'label': 'Capacity (Liters)',
            'type': 'dropdown',
            'required': false,
            'options': [
              'Below 200L',
              '200-300L',
              '300-400L',
              '400-500L',
              'Above 500L'
            ],
            'hint': 'Select approximate capacity',
          },
          {
            'key': 'issueType',
            'label': 'Primary Issue',
            'type': 'dropdown',
            'required': true,
            'options': [
              'Not cooling properly',
              'Strange noises',
              'Water leakage',
              'Door not closing properly',
              'Ice maker not working',
              'Freezer issues',
              'Electrical problems',
              'General maintenance',
              'Other'
            ],
            'hint': 'Select the main issue',
          },
          {
            'key': 'purchaseYear',
            'label': 'Purchase Year (Optional)',
            'type': 'number',
            'required': false,
            'hint': 'When did you purchase it?',
          },
        ];
      default:
        return [];
    }
  }

  void _updateFormData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(widget.formData);
    updatedData[key] = value;
    widget.onFormDataChanged(updatedData);

    // Clear validation error when user updates the field
    if (_validationErrors.containsKey(key)) {
      setState(() {
        _validationErrors.remove(key);
      });
    }
  }

  String? _validateField(Map<String, dynamic> field, String? value) {
    final isRequired = field['required'] as bool;
    final fieldType = field['type'] as String;

    if (isRequired && (value == null || value.isEmpty)) {
      return '${field['label']} is required';
    }

    if (value != null && value.isNotEmpty) {
      switch (fieldType) {
        case 'number':
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          break;
        case 'text':
          if (value.length < 2) {
            return 'Please enter at least 2 characters';
          }
          break;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fields = _getServiceSpecificFields();

    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...fields.map((field) => _buildField(field)).toList(),
      ],
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final type = field['type'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final hint = field['hint'] as String?;
    final hasError = _validationErrors.containsKey(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (type) {
            'dropdown' => _buildDropdownField(field),
            'radio' => _buildRadioField(field),
            'date' => _buildDateField(field),
            'number' => _buildNumberField(field),
            'text' => _buildTextField(field),
            _ => const SizedBox.shrink(),
          },
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _validationErrors[key]!,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final options = field['options'] as List<String>;
    final hint = field['hint'] as String?;
    final currentValue = widget.formData[key] as String?;
    final hasError = _validationErrors.containsKey(key);

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.deepPurple,
          ),
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        _updateFormData(key, value);
      },
    );
  }

  Widget _buildRadioField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final options = field['options'] as List<String>;
    final currentValue = widget.formData[key] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: currentValue,
            onChanged: (value) {
              _updateFormData(key, value);
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final hint = field['hint'] as String?;
    final currentValue = widget.formData[key] as String?;
    final hasError = _validationErrors.containsKey(key);

    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.deepPurple,
          ),
        ),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 30)),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          final formattedDate = '${date.day}/${date.month}/${date.year}';
          _controllers[key]!.text = formattedDate;
          _updateFormData(key, formattedDate);
        }
      },
    );
  }

  Widget _buildNumberField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final hint = field['hint'] as String?;
    final hasError = _validationErrors.containsKey(key);

    return TextFormField(
      controller: _controllers[key],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.deepPurple,
          ),
        ),
      ),
      onChanged: (value) {
        _updateFormData(key, value);
      },
    );
  }

  Widget _buildTextField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = field['label'] as String;
    final required = field['required'] as bool;
    final hint = field['hint'] as String?;
    final hasError = _validationErrors.containsKey(key);

    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.deepPurple,
          ),
        ),
      ),
      onChanged: (value) {
        _updateFormData(key, value);
      },
    );
  }
}
