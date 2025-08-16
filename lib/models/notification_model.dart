import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String recipient;
  final String? relatedBookingId;
  final String? relatedUserId;
  final String? relatedEmployeeId;
  bool isRead;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String priority;
  final String deliveryMethod;
  final String deliveryStatus;
  final bool actionRequired;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipient,
    this.relatedBookingId,
    this.relatedUserId,
    this.relatedEmployeeId,
    required this.isRead,
    this.readAt,
    this.deliveredAt,
    required this.priority,
    this.deliveryMethod = 'both',
    this.deliveryStatus = 'pending',
    this.actionRequired = false,
    this.actionUrl,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      recipient: json['recipient'] ?? '',
      relatedBookingId:
          json['relatedBooking']?['_id'] ?? json['relatedBooking'],
      relatedUserId: json['relatedUser']?['_id'] ?? json['relatedUser'],
      relatedEmployeeId:
          json['relatedEmployee']?['_id'] ?? json['relatedEmployee'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      priority: json['priority'] ?? 'medium',
      deliveryMethod: json['deliveryMethod'] ?? 'both',
      deliveryStatus: json['deliveryStatus'] ?? 'pending',
      actionRequired: json['actionRequired'] ?? false,
      actionUrl: json['actionUrl'],
      data: json['data'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get typeDisplayName {
    switch (type) {
      // Booking lifecycle
      case 'booking_created':
        return 'New Booking';
      case 'booking_accepted':
        return 'Booking Confirmed';
      case 'booking_rejected':
        return 'Booking Declined';
      case 'booking_updated':
        return 'Booking Updated';
      case 'booking_cancelled':
        return 'Booking Cancelled';

      // Worker assignment
      case 'worker_assigned':
        return 'Technician Assigned';
      case 'worker_assigned_admin':
        return 'Worker Assigned';
      case 'worker_assigned_worker':
        return 'New Assignment';

      // Service progress
      case 'service_started':
        return 'Service Started';
      case 'service_in_progress':
        return 'Service In Progress';
      case 'service_completed':
        return 'Service Completed';
      case 'service_completed_admin':
        return 'Service Completed';

      // Payment
      case 'payment_required':
        return 'Payment Required';
      case 'payment_received':
        return 'Payment Received';
      case 'payment_failed':
        return 'Payment Failed';

      // Reminders
      case 'service_reminder':
        return 'Service Reminder';
      case 'payment_reminder':
        return 'Payment Reminder';

      // System
      case 'system':
        return 'System';

      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : word)
            .join(' ');
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      // Booking lifecycle
      case 'booking_created':
        return Icons.add_circle_outline;
      case 'booking_accepted':
        return Icons.check_circle_outline;
      case 'booking_rejected':
        return Icons.cancel_outlined;
      case 'booking_updated':
        return Icons.edit_outlined;
      case 'booking_cancelled':
        return Icons.cancel;

      // Worker assignment
      case 'worker_assigned':
      case 'worker_assigned_admin':
      case 'worker_assigned_worker':
        return Icons.person_add_outlined;

      // Service progress
      case 'service_started':
        return Icons.play_circle_outline;
      case 'service_in_progress':
        return Icons.settings_outlined;
      case 'service_completed':
      case 'service_completed_admin':
        return Icons.check_circle;

      // Payment
      case 'payment_required':
        return Icons.payment_outlined;
      case 'payment_received':
        return Icons.payment;
      case 'payment_failed':
        return Icons.error_outline;

      // Reminders
      case 'service_reminder':
        return Icons.schedule_outlined;
      case 'payment_reminder':
        return Icons.payment_outlined;

      // System
      case 'system':
        return Icons.settings;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color get typeColor {
    switch (type) {
      // Booking lifecycle
      case 'booking_created':
        return Colors.blue;
      case 'booking_accepted':
        return Colors.green;
      case 'booking_rejected':
      case 'booking_cancelled':
        return Colors.red;
      case 'booking_updated':
        return Colors.orange;

      // Worker assignment
      case 'worker_assigned':
      case 'worker_assigned_admin':
      case 'worker_assigned_worker':
        return Colors.purple;

      // Service progress
      case 'service_started':
        return Colors.blue;
      case 'service_in_progress':
        return Colors.orange;
      case 'service_completed':
      case 'service_completed_admin':
        return Colors.green;

      // Payment
      case 'payment_required':
        return Colors.amber;
      case 'payment_received':
        return Colors.green;
      case 'payment_failed':
        return Colors.red;

      // Reminders
      case 'service_reminder':
      case 'payment_reminder':
        return Colors.orange;

      // System
      case 'system':
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }

  bool get isWorkflowNotification {
    return [
      'booking_created',
      'booking_accepted',
      'booking_rejected',
      'worker_assigned',
      'worker_assigned_admin',
      'worker_assigned_worker',
      'service_started',
      'service_in_progress',
      'service_completed',
      'service_completed_admin',
      'payment_required',
      'payment_received',
      'payment_failed'
    ].contains(type);
  }

  bool get isActionable {
    return actionRequired && actionUrl != null;
  }

  String? get serviceType {
    return data?['serviceType'];
  }

  String? get customerName {
    return data?['customerName'];
  }

  String? get bookingStatus {
    return data?['status'];
  }

  double? get paymentAmount {
    final amount = data?['paymentAmount'];
    return amount?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'recipient': recipient,
      'relatedBookingId': relatedBookingId,
      'relatedUserId': relatedUserId,
      'relatedEmployeeId': relatedEmployeeId,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'priority': priority,
      'deliveryMethod': deliveryMethod,
      'deliveryStatus': deliveryStatus,
      'actionRequired': actionRequired,
      'actionUrl': actionUrl,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
