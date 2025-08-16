import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class PaymentProofService {
  static const String baseUrl = 'http://192.168.1.100:3000/api';
  
  /// Pick image from gallery or camera
  static Future<File?> pickPaymentProof({
    required ImageSource source,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  /// Upload payment proof to server
  static Future<bool> uploadPaymentProof({
    required String bookingId,
    required File imageFile,
    required double amount,
    String? customerName,
    String? transactionId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment/upload-proof'),
      );
      
      // Add form fields
      request.fields['bookingId'] = bookingId;
      request.fields['amount'] = amount.toString();
      if (customerName != null) request.fields['customerName'] = customerName;
      if (transactionId != null) request.fields['transactionId'] = transactionId;
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'paymentProof',
          imageFile.path,
        ),
      );
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        print('✅ Payment proof uploaded successfully');
        return true;
      } else {
        print('❌ Failed to upload payment proof: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading payment proof: $e');
      return false;
    }
  }
  
  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  /// Validate image file
  static bool isValidImageFile(File file) {
    final String extension = file.path.toLowerCase();
    return extension.endsWith('.jpg') || 
           extension.endsWith('.jpeg') || 
           extension.endsWith('.png');
  }
  
  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    int sizeInBytes = file.lengthSync();
    return sizeInBytes / (1024 * 1024);
  }
}