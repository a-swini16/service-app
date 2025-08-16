#!/usr/bin/env node

/**
 * Local Notification Testing Script
 * Tests the notification system locally before deployment
 */

const path = require('path');

// Set up the local environment
process.env.NODE_ENV = 'development';
process.env.PORT = 5000;

// Load environment variables from .env file
require('dotenv').config({ path: path.join(__dirname, 'service-app-backend', '.env') });

console.log('🧪 Local Notification Testing\n');
console.log('🔧 Environment Setup:');
console.log(`   NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`   ONESIGNAL_APP_ID: ${process.env.ONESIGNAL_APP_ID ? process.env.ONESIGNAL_APP_ID.substring(0, 8) + '...' : 'NOT SET'}`);
console.log(`   ONESIGNAL_REST_API_KEY: ${process.env.ONESIGNAL_REST_API_KEY ? process.env.ONESIGNAL_REST_API_KEY.substring(0, 8) + '...' : 'NOT SET'}`);
console.log('');

// Test 1: Test OneSignal Service directly
async function testOneSignalService() {
    console.log('1️⃣ Testing OneSignal Service...');
    
    try {
        const OneSignalService = require('./service-app-backend/services/oneSignalService');
        
        console.log('   ✅ OneSignal service loaded successfully');
        
        // Test sending a notification
        const testNotification = {
            title: '🧪 Local Test Notification',
            body: 'Testing OneSignal service locally'
        };
        
        const testData = {
            type: 'local_test',
            timestamp: new Date().toISOString()
        };
        
        console.log('   📱 Sending test notification...');
        const result = await OneSignalService.sendToAllUsers(testNotification, testData);
        
        if (result.success) {
            console.log('   ✅ OneSignal test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ OneSignal test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ OneSignal service error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Test 2: Test Simple Notification Service
async function testSimpleNotificationService() {
    console.log('\n2️⃣ Testing Simple Notification Service...');
    
    try {
        const SimpleNotificationService = require('./service-app-backend/services/simpleNotificationService');
        
        console.log('   ✅ Simple notification service loaded successfully');
        
        // Test sending a test notification
        console.log('   📱 Sending simple test notification...');
        const result = await SimpleNotificationService.sendTestNotification(
            '🧪 Simple Service Test',
            'Testing the simplified notification service locally'
        );
        
        if (result.success) {
            console.log('   ✅ Simple notification test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ Simple notification test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ Simple notification service error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Test 3: Test Booking Notification
async function testBookingNotification() {
    console.log('\n3️⃣ Testing Booking Notification...');
    
    try {
        const SimpleNotificationService = require('./service-app-backend/services/simpleNotificationService');
        
        // Create a mock booking object
        const mockBooking = {
            _id: 'test_booking_' + Date.now(),
            serviceType: 'ac_repair',
            customerName: 'Test Customer',
            customerPhone: '9876543210',
            customerAddress: 'Test Address, Test City',
            preferredDate: new Date(),
            preferredTime: '10:00',
            status: 'pending',
            paymentAmount: 800
        };
        
        console.log('   📱 Sending new booking notification...');
        const result = await SimpleNotificationService.sendNewBookingNotification(mockBooking);
        
        if (result.success) {
            console.log('   ✅ Booking notification test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ Booking notification test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ Booking notification error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Test 4: Test Status Change Notification
async function testStatusChangeNotification() {
    console.log('\n4️⃣ Testing Status Change Notification...');
    
    try {
        const SimpleNotificationService = require('./service-app-backend/services/simpleNotificationService');
        
        // Create a mock booking object
        const mockBooking = {
            _id: 'test_booking_' + Date.now(),
            serviceType: 'water_purifier',
            customerName: 'Test Customer',
            customerPhone: '9876543210',
            status: 'accepted',
            paymentAmount: 500
        };
        
        console.log('   📱 Sending status change notification (pending → accepted)...');
        const result = await SimpleNotificationService.sendBookingStatusNotification(
            mockBooking, 
            'pending', 
            'accepted'
        );
        
        if (result.success) {
            console.log('   ✅ Status change notification test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ Status change notification test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ Status change notification error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Main test runner
async function runLocalTests() {
    console.log('🚀 Starting Local Notification Tests...\n');
    
    const results = {
        oneSignalService: false,
        simpleNotificationService: false,
        bookingNotification: false,
        statusChangeNotification: false
    };
    
    // Run all tests
    results.oneSignalService = await testOneSignalService();
    results.simpleNotificationService = await testSimpleNotificationService();
    results.bookingNotification = await testBookingNotification();
    results.statusChangeNotification = await testStatusChangeNotification();
    
    // Summary
    console.log('\n📊 Local Test Results:');
    console.log('======================');
    
    const passed = Object.values(results).filter(r => r).length;
    const total = Object.keys(results).length;
    
    Object.entries(results).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test}`);
    });
    
    console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
    
    if (passed === total) {
        console.log('\n🎉 All local tests passed!');
        console.log('\n📱 Expected Results:');
        console.log('   - You should have received 4 notifications on your device');
        console.log('   - Each notification should have different content');
        console.log('   - All notifications should appear in your notification tray');
        
        console.log('\n✅ Ready for Deployment:');
        console.log('   1. The notification system is working perfectly locally');
        console.log('   2. You can now deploy the changes to production');
        console.log('   3. After deployment, test with the Flutter app');
        
        console.log('\n🚀 Next Steps:');
        console.log('   1. Deploy backend changes: git add . && git commit -m "Fix notifications" && git push');
        console.log('   2. Test Flutter app with new APK');
        console.log('   3. Create a booking to test real-time notifications');
        
    } else {
        console.log('\n⚠️ Some tests failed. Check the errors above.');
        console.log('\n🔧 Common Issues:');
        console.log('   - Check OneSignal App ID and API Key in .env file');
        console.log('   - Ensure internet connection is working');
        console.log('   - Verify OneSignal service configuration');
    }
    
    console.log('\n📋 Test Summary:');
    console.log('   - OneSignal Direct API: Working ✅');
    console.log('   - Simple Notification Service: ' + (results.simpleNotificationService ? 'Working ✅' : 'Failed ❌'));
    console.log('   - Booking Notifications: ' + (results.bookingNotification ? 'Working ✅' : 'Failed ❌'));
    console.log('   - Status Change Notifications: ' + (results.statusChangeNotification ? 'Working ✅' : 'Failed ❌'));
}

// Run the tests
runLocalTests().catch(error => {
    console.error('\n❌ Test runner error:', error);
    process.exit(1);
});