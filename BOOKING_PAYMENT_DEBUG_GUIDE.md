# 🔧 Booking & Payment Debug Guide

## 🎯 Issues to Fix

1. **No bookings showing in user account** - Bookings tab is empty
2. **Payment amount form not appearing** - Navigation flow not working

## 🛠️ Debug Tools Created

### 1. Debug Booking Screen
**File**: `lib/screens/debug_booking_screen.dart`
**Access**: Purple bug icon in home screen app bar

**Features:**
- ✅ Create test bookings
- ✅ Load and display user bookings  
- ✅ Test payment amount form
- ✅ Test cash payment info screen
- ✅ Show service pricing
- ✅ Real-time status updates

### 2. Backend API Test Script
**File**: `service-app-backend/test-booking-api.js`
**Usage**: `node test-booking-api.js`

**Tests:**
- ✅ User login
- ✅ Booking creation
- ✅ Fetch user bookings
- ✅ Payment amount update

### 3. Simple Booking Test
**File**: `test_booking_creation.dart`
**Usage**: Run in Flutter app for basic testing

## 🚀 How to Debug

### Step 1: Access Debug Screen
1. Open the app
2. Look for purple **bug icon** in home screen app bar
3. Tap it to open Debug Booking Screen

### Step 2: Test Booking Creation
1. In debug screen, tap **"Create Test Booking"**
2. Check if booking is created successfully
3. Status will show: "✅ Test booking created successfully!"

### Step 3: Test Booking Loading
1. Tap **"Load User Bookings"**
2. Check if bookings appear in the list
3. Should show: "✅ Loaded X bookings"

### Step 4: Test Payment Forms
1. If bookings are loaded, tap **"Test Payment Amount Form"**
2. Should navigate to payment amount form
3. Try entering different amounts and see validation

### Step 5: Test Cash Payment Flow
1. Tap **"Test Cash Payment Info"**
2. Should show cash payment info screen
3. Tap **"Confirm Payment Amount"** button
4. Should navigate to payment amount form

## 🔍 Common Issues & Solutions

### Issue 1: No Bookings Loading
**Symptoms:** "No bookings found" message
**Possible Causes:**
- User not logged in properly
- API endpoint not working
- Database connection issues

**Debug Steps:**
1. Check debug screen status messages
2. Run backend API test: `node service-app-backend/test-booking-api.js`
3. Check server logs for errors
4. Verify user authentication

### Issue 2: Payment Form Not Opening
**Symptoms:** Button tap doesn't navigate to form
**Possible Causes:**
- Route not registered properly
- Missing arguments in navigation
- Screen import issues

**Debug Steps:**
1. Check console for navigation errors
2. Verify route exists in `main.dart`
3. Check if arguments are passed correctly
4. Test with debug screen buttons

### Issue 3: Backend API Errors
**Symptoms:** API calls failing
**Possible Causes:**
- Server not running
- Authentication issues
- Database connection problems

**Debug Steps:**
1. Check if server is running on port 5000
2. Test API with: `curl http://localhost:5000/api/bookings/user`
3. Check server console for errors
4. Verify database connection

## 📱 Debug Screen Interface

```
┌─────────────────────────────────┐
│ 🔧 Debug Status                 │
│ Ready to test                   │
├─────────────────────────────────┤
│ 🧪 Test Actions                 │
│ [Create Test Booking]           │
│ [Load User Bookings]            │
│ [Test Payment Amount Form]      │
│ [Test Cash Payment Info]        │
├─────────────────────────────────┤
│ 💰 Service Pricing              │
│ Water Purifier Service    ₹500  │
│ AC Repair Service         ₹800  │
│ Refrigerator Repair       ₹600  │
├─────────────────────────────────┤
│ 📚 User Bookings (X)            │
│ [Booking 1] AC Repair - pending │
│ [Booking 2] Water Purifier...   │
└─────────────────────────────────┘
```

## 🔧 Backend API Test Results

Expected output from `node test-booking-api.js`:

```
🧪 Testing Booking API...

1️⃣ Testing user login...
✅ Login successful
👤 User: testuser

2️⃣ Creating test booking...
✅ Booking created successfully
📋 Booking ID: 507f1f77bcf86cd799439011
🔧 Service: ac_repair
👤 Customer: Test Customer

3️⃣ Fetching user bookings...
✅ Found 1 bookings
  1. ac_repair - Test Customer (pending)

4️⃣ Testing payment amount update...
✅ Payment amount updated successfully
💰 Actual Amount: ₹850
📊 Expected Amount: ₹800
📈 Difference: ₹50

🎉 All tests completed successfully!
```

## 🎯 Quick Fix Checklist

### For "No Bookings" Issue:
- [ ] Server is running on port 5000
- [ ] User can login successfully
- [ ] Test booking creation works
- [ ] API returns bookings data
- [ ] Frontend displays bookings correctly

### For "Payment Form Not Working" Issue:
- [ ] Route `/payment-amount-form` exists in main.dart
- [ ] Screen import is correct
- [ ] Navigation arguments are passed
- [ ] Screen renders without errors
- [ ] Form validation works

### For Backend Issues:
- [ ] MongoDB connection is working
- [ ] User authentication is working
- [ ] Booking creation API works
- [ ] Payment amount update API works
- [ ] No server errors in console

## 🚀 Testing Flow

1. **Open Debug Screen** (purple bug icon)
2. **Create Test Booking** → Should succeed
3. **Load Bookings** → Should show the created booking
4. **Test Payment Form** → Should open form with pre-filled amount
5. **Enter Payment Amount** → Should validate and submit
6. **Check Backend** → Should update booking with payment info

## 📞 If Issues Persist

1. **Check Server Logs**: Look for errors in backend console
2. **Check Flutter Logs**: Look for errors in Flutter console  
3. **Test API Directly**: Use the backend test script
4. **Verify Database**: Check if bookings are actually created in MongoDB
5. **Check Authentication**: Ensure user is properly logged in

---

**🎊 Use these debug tools to identify and fix the booking and payment issues!**

The debug screen provides a comprehensive way to test all functionality step by step.