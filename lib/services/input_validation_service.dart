class InputValidationService {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Phone validation
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone.trim());
  }

  // Password strength validation
  static Map<String, dynamic> validatePassword(String password) {
    final result = <String, dynamic>{
      'isValid': false,
      'errors': <String>[],
      'strength': 'weak',
    };

    if (password.isEmpty) {
      (result['errors'] as List<String>).add('Password cannot be empty');
      return result;
    }

    if (password.length < 8) {
      (result['errors'] as List<String>).add('Password must be at least 8 characters long');
    }

    if (password.length > 128) {
      (result['errors'] as List<String>).add('Password cannot exceed 128 characters');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      (result['errors'] as List<String>).add('Password must contain at least one lowercase letter');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      (result['errors'] as List<String>).add('Password must contain at least one uppercase letter');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      (result['errors'] as List<String>).add('Password must contain at least one number');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      (result['errors'] as List<String>).add('Password must contain at least one special character');
    }

    // Check for common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      (result['errors'] as List<String>).add('Password cannot contain repeated characters');
    }

    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(password)) {
      (result['errors'] as List<String>).add('Password cannot contain sequential characters');
    }

    // Common passwords check
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey'
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      (result['errors'] as List<String>).add('Password is too common');
    }

    // Calculate strength
    int strengthScore = 0;
    if (password.length >= 8) strengthScore++;
    if (password.length >= 12) strengthScore++;
    if (RegExp(r'[a-z]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[0-9]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strengthScore++;

    if (strengthScore <= 2) {
      result['strength'] = 'weak';
    } else if (strengthScore <= 4) {
      result['strength'] = 'medium';
    } else {
      result['strength'] = 'strong';
    }

    result['isValid'] = (result['errors'] as List).isEmpty;
    return result;
  }

  // Name validation
  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2 || name.trim().length > 50) {
      return false;
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(name.trim());
  }

  // Address validation
  static bool isValidAddress(String address) {
    return address.trim().length >= 10 && address.trim().length <= 300;
  }

  // Service type validation
  static bool isValidServiceType(String serviceType) {
    const validTypes = ['water_purifier', 'ac_repair', 'refrigerator_repair'];
    return validTypes.contains(serviceType);
  }

  // Date validation
  static bool isValidFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    return inputDate.isAfter(today) || inputDate.isAtSameMomentAs(today);
  }

  // Time validation
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // Sanitize input to prevent XSS
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove script tags and their content
    sanitized = sanitized.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '');

    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // Remove on* event handlers
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }

  // Detect potential security threats
  static List<String> detectSecurityThreats(String input) {
    final threats = <String>[];

    if (input.isEmpty) return threats;

    // SQL injection patterns
    final sqlPatterns = [
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b', caseSensitive: false),
      RegExp(r'\b(OR|AND)\b.*[=<>]', caseSensitive: false),
      RegExp(r'\b(WAITFOR|DELAY)\b', caseSensitive: false),
      RegExp(r'--|\/\*|\*\/|\;', caseSensitive: false),
    ];

    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(input)) {
        threats.add('Potential SQL injection detected');
        break;
      }
    }

    // XSS patterns
    final xssPatterns = [
      RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false),
      RegExp(r'<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<img[^>]+src[^>]*>', caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        threats.add('Potential XSS attempt detected');
        break;
      }
    }

    // Path traversal
    if (input.contains('../') || input.contains('..\\')) {
      threats.add('Path traversal attempt detected');
    }

    // Command injection
    if (RegExp(r'[;&|`$(){}[\]\\]').hasMatch(input)) {
      threats.add('Potential command injection detected');
    }

    return threats;
  }

  // Validate and sanitize form data
  static Map<String, dynamic> validateFormData(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      'isValid': true,
      'errors': <String, List<String>>{},
      'sanitizedData': <String, dynamic>{},
      'threats': <String>[],
    };

    data.forEach((key, value) {
      if (value is String) {
        // Detect threats
        final threats = detectSecurityThreats(value);
        if (threats.isNotEmpty) {
          (result['threats'] as List<String>).addAll(threats);
          result['isValid'] = false;
        }

        // Sanitize
        final sanitized = sanitizeInput(value);
        (result['sanitizedData'] as Map<String, dynamic>)[key] = sanitized;

        // Field-specific validation
        final fieldErrors = <String>[];

        switch (key) {
          case 'name':
          case 'customerName':
            if (!isValidName(sanitized)) {
              fieldErrors.add('Name must be 2-50 characters and contain only letters and spaces');
            }
            break;
          case 'email':
            if (!isValidEmail(sanitized)) {
              fieldErrors.add('Please enter a valid email address');
            }
            break;
          case 'phone':
          case 'customerPhone':
            if (!isValidPhone(sanitized)) {
              fieldErrors.add('Phone number must be exactly 10 digits');
            }
            break;
          case 'password':
            final passwordValidation = validatePassword(sanitized);
            if (!passwordValidation['isValid']) {
              fieldErrors.addAll(List<String>.from(passwordValidation['errors']));
            }
            break;
          case 'address':
          case 'customerAddress':
            if (!isValidAddress(sanitized)) {
              fieldErrors.add('Address must be between 10 and 300 characters');
            }
            break;
          case 'serviceType':
            if (!isValidServiceType(sanitized)) {
              fieldErrors.add('Invalid service type selected');
            }
            break;
          case 'preferredTime':
            if (!isValidTime(sanitized)) {
              fieldErrors.add('Please enter a valid time in HH:MM format');
            }
            break;
        }

        if (fieldErrors.isNotEmpty) {
          (result['errors'] as Map<String, List<String>>)[key] = fieldErrors;
          result['isValid'] = false;
        }
      } else if (value is DateTime) {
        // Handle DateTime fields
        (result['sanitizedData'] as Map<String, dynamic>)[key] = value;
      } else {
        // Handle other types
        (result['sanitizedData'] as Map<String, dynamic>)[key] = value;
      }
    });

    return result;
  }

  // Validate booking data specifically
  static Map<String, dynamic> validateBookingData(Map<String, dynamic> bookingData) {
    final validation = validateFormData(bookingData);

    // Additional booking-specific validations
    if (bookingData.containsKey('preferredDate')) {
      try {
        final date = bookingData['preferredDate'] is String
            ? DateTime.parse(bookingData['preferredDate'])
            : bookingData['preferredDate'] as DateTime;

        if (!isValidFutureDate(date)) {
          final errors = validation['errors'] as Map<String, List<String>>;
          errors['preferredDate'] = ['Preferred date must be today or in the future'];
          validation['isValid'] = false;
        }
      } catch (e) {
        final errors = validation['errors'] as Map<String, List<String>>;
        errors['preferredDate'] = ['Please enter a valid date'];
        validation['isValid'] = false;
      }
    }

    return validation;
  }

  // Validate user registration data
  static Map<String, dynamic> validateRegistrationData(Map<String, dynamic> userData) {
    final validation = validateFormData(userData);

    // Additional registration-specific validations
    if (userData.containsKey('confirmPassword') && userData.containsKey('password')) {
      if (userData['password'] != userData['confirmPassword']) {
        final errors = validation['errors'] as Map<String, List<String>>;
        errors['confirmPassword'] = ['Passwords do not match'];
        validation['isValid'] = false;
      }
    }

    return validation;
  }

  // Check if string contains only safe characters
  static bool containsOnlySafeCharacters(String input) {
    if (input.isEmpty) return true;
    // Allow alphanumeric, spaces, and common punctuation
    final safePattern = RegExp(r'^[a-zA-Z0-9\s\.,!?\-_@#$%&*()+=:;/\\]+$');
    return safePattern.hasMatch(input);
  }

  // Validate file upload
  static Map<String, dynamic> validateFileUpload(String fileName, int fileSize) {
    final result = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
    };

    if (fileName.isEmpty) {
      (result['errors'] as List<String>).add('File name cannot be empty');
      result['isValid'] = false;
      return result;
    }

    // Check file extension
    final lastDotIndex = fileName.lastIndexOf('.');

    if (lastDotIndex == -1 || lastDotIndex == fileName.length - 1) {
      (result['errors'] as List<String>).add('Invalid file extension');
      result['isValid'] = false;
      return result;
    }

    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx'];
    final extension = fileName.substring(lastDotIndex).toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      (result['errors'] as List<String>).add('File type not allowed. Allowed types: ${allowedExtensions.join(', ')}');
      result['isValid'] = false;
    }

    // Check file size (5MB limit)
    if (fileSize > 5 * 1024 * 1024) {
      (result['errors'] as List<String>).add('File size cannot exceed 5MB');
      result['isValid'] = false;
    }

    // Check for suspicious file names
    if (fileName.contains('..') || fileName.contains('/') || fileName.contains('\\')) {
      (result['errors'] as List<String>).add('Invalid file name');
      result['isValid'] = false;
    }

    return result;
  }
}