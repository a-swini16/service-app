# Om Enterprises Service Booking App

A complete service booking application with Flutter frontend and Node.js backend, featuring real-time notifications, admin panel, and payment processing.

## Features

### User Features
- **Service Booking**: Book water purifier, AC repair, and refrigerator repair services
- **Real-time Notifications**: Get notified when admin accepts/rejects bookings
- **Booking Status Tracking**: Track your booking from submission to completion
- **Payment Processing**: Multiple payment options including cash on service
- **User Dashboard**: View booking history and notifications

### Admin Features
- **Booking Management**: Accept, reject, and assign workers to bookings
- **Real-time Dashboard**: Monitor all bookings and statistics
- **Worker Assignment**: Assign specialized technicians to accepted bookings
- **Notification System**: Real-time notifications for new bookings
- **Payment Tracking**: Monitor payment status and completion

### Technical Features
- **Real-time Updates**: Socket.IO for instant notifications
- **Secure Authentication**: JWT-based auth for users and admins
- **Production Ready**: Error handling, validation, and logging
- **Responsive Design**: Works on all device sizes
- **State Management**: Provider pattern for Flutter state management

## Tech Stack

### Backend
- **Node.js** with Express.js
- **MongoDB** with Mongoose ODM
- **Socket.IO** for real-time communication
- **JWT** for authentication
- **bcryptjs** for password hashing

### Frontend
- **Flutter** with Dart
- **Provider** for state management
- **HTTP** for API communication
- **Socket.IO Client** for real-time updates
- **Secure Storage** for token management

## Project Structure

```
├── service-app-backend/          # Node.js Backend
│   ├── models/                   # Database models
│   ├── routes/                   # API routes
│   ├── services/                 # Business logic
│   ├── middleware/               # Auth middleware
│   ├── seeders/                  # Database seeders
│   └── server.js                 # Main server file
│
├── lib/                          # Flutter Frontend
│   ├── models/                   # Data models
│   ├── providers/                # State management
│   ├── screens/                  # UI screens
│   ├── services/                 # API services
│   ├── widgets/                  # Reusable widgets
│   └── main.dart                 # Main app file
│
└── README.md                     # This file
```

**Om Enterprises** - Your Trusted Service Partner
