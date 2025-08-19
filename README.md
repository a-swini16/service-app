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

## Setup Instructions

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (v3.0 or higher)
- MongoDB Atlas account or local MongoDB
- Android Studio / VS Code

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd service-app-backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   - Update `.env` file with your MongoDB connection string
   - Set JWT_SECRET to a secure random string
   ```env
   NODE_ENV=development
   PORT=5000
   MONGO_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret_key
   JWT_EXPIRE=30d
   ```

4. **Setup Database (Recommended)**
   ```bash
   # One-command setup (creates admin + employees)
   npm run setup
   ```
   
   **OR Manual Setup:**
   ```bash
   # Create admin user
   npm run seed:admin
   
   # Reset and create employees (if you get duplicate key errors)
   npm run reset:employees
   npm run seed:employees
   
   # Optional: Create test bookings
   npm run seed:bookings
   ```

5. **Start Backend Server**
   ```bash
   npm run dev
   ```
   Server will run on `http://localhost:5000`

6. **Test API (Optional)**
   ```bash
   npm run test-api
   ```
   This will verify all endpoints are working correctly.

### Frontend Setup

1. **Navigate to project root**
   ```bash
   cd ..
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API Configuration**
   - Open `lib/constants/app_constants.dart`
   - Update `baseUrl` to match your backend URL:
   ```dart
   // For Android emulator
   static const String baseUrl = 'http://10.0.2.2:5000/api';
   
   // For physical device (replace with your IP)
   static const String baseUrl = 'http://192.168.1.100:5000/api';
   ```

4. **Run Flutter App**
   ```bash
   flutter run
   ```

## Default Credentials

### Admin Login
- **Username**: `admin`
- **Password**: `admin123`

### Test User
You can register a new user through the app or use the registration screen.

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/admin/login` - Admin login
- `GET /api/auth/profile` - Get user profile

### Bookings
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/my-bookings` - Get user bookings
- `GET /api/bookings` - Get all bookings (admin)
- `PUT /api/bookings/:id/status` - Update booking status
- `PUT /api/admin/bookings/:id/accept` - Accept booking
- `PUT /api/admin/bookings/:id/reject` - Reject booking
- `PUT /api/admin/bookings/:id/assign` - Assign worker

### Notifications
- `GET /api/notifications/admin` - Get admin notifications
- `GET /api/notifications/user/:userId` - Get user notifications
- `PUT /api/notifications/:id/read` - Mark as read

### Employees
- `GET /api/employees/available` - Get available workers
- `POST /api/employees` - Create employee (admin)
- `PUT /api/employees/:id` - Update employee (admin)

## Workflow

### Complete Booking Flow

1. **User Books Service**
   - User selects service type
   - Fills booking form with details
   - Submits booking (status: `pending`)
   - Admin receives real-time notification

2. **Admin Reviews Booking**
   - Admin sees booking in dashboard
   - Can accept or reject with reason
   - User receives notification of decision

3. **Worker Assignment** (if accepted)
   - Admin assigns available worker
   - Worker specialization matches service type
   - User notified of worker assignment

4. **Service Execution**
   - Worker updates status to `in_progress`
   - Worker completes service (status: `completed`)
   - User receives completion notification

5. **Payment Processing**
   - Payment screen appears for user
   - User completes payment
   - Admin receives payment confirmation

## Real-time Features

The app uses Socket.IO for real-time communication:

- **New Booking Notifications**: Admins get instant notifications
- **Status Updates**: Users get real-time booking status changes
- **Worker Assignment**: Users notified when worker is assigned
- **Payment Confirmations**: Real-time payment status updates

## Database Schema

### User Model
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  phone: String,
  address: String,
  isActive: Boolean,
  timestamps: true
}
```

### Booking Model
```javascript
{
  user: ObjectId (ref: User),
  serviceType: String (enum),
  customerName: String,
  customerPhone: String,
  customerAddress: String,
  description: String,
  preferredDate: Date,
  preferredTime: String,
  status: String (enum),
  assignedEmployee: ObjectId (ref: Employee),
  paymentStatus: String (enum),
  paymentAmount: Number,
  actualAmount: Number,
  paymentMethod: String (enum),
  adminNotes: String,
  rejectionReason: String,
  timestamps: true
}
```

### Employee Model
```javascript
{
  name: String,
  email: String (unique),
  phone: String,
  specializations: [String],
  isAvailable: Boolean,
  currentBookings: [ObjectId],
  completedBookings: Number,
  rating: Number,
  timestamps: true
}
```

## Deployment

### Backend Deployment
1. Deploy to services like Heroku, Railway, or DigitalOcean
2. Set environment variables
3. Ensure MongoDB connection is configured
4. Update CORS settings for production

### Frontend Deployment
1. Update API base URL for production
2. Build APK: `flutter build apk --release`
3. Deploy to Google Play Store or distribute APK

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions:
- Create an issue in the repository
- Contact: support@omenterprises.com

---

**Om Enterprises** - Your Trusted Service Partner