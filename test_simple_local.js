#!/usr/bin/env node

/**
 * Simple Local Notification Test
 * Tests the notification system without external dependencies
 */

console.log('🧪 Simple Local Notification Test\n');

// Set up OneSignal configuration directly
const ONESIGNAL_CONFIG = {
    appId: 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d',
    restApiKey: 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa'
};

console.log('🔧 OneSignal Configuration:');
console.log(`   App ID: ${ONESIGNAL_CONFIG.appId.substring(0, 8)}...`);
console.log(`   API Key: ${ONESIGNAL_CONFIG.restApiKey.substring(0, 8)}...`);
console.log('');

// Test 1: Direct OneSignal API Test
async function testDirectOneSignal() {
    console.log('1️⃣ Testing Direct OneSignal API...');
    
    const https = require('https');
    
    const message = {
        app_id: ONESIGNAL_CONFIG.appId,
        included_segments: ['All'],
        headings: { en: '🧪 Local Test - Direct API' },
        contents: { en: 'Testing OneSignal API directly from local script' },
        data: {
            type: 'local_direct_test',
            timestamp: new Date().toISOString()
        }
    };

    return new Promise((resolve) => {
        const postData = JSON.stringify(message);

        const options = {
            hostname: 'onesignal.com',
            port: 443,
            path: '/api/v1/notifications',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': `Basic ${ONESIGNAL_CONFIG.restApiKey}`,
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    
                    if (response.id) {
                        console.log('   ✅ Direct OneSignal test successful!');
                        console.log(`      Notification ID: ${response.id}`);
                        console.log(`      Recipients: ${response.recipients || 'Unknown'}`);
                        resolve(true);
                    } else {
                        console.log('   ❌ Direct OneSignal test failed:');
                        console.log(`      Error: ${JSON.stringify(response.errors || response)}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log('   ❌ Response parse error:', error.message);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log('   ❌ Request error:', error.message);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test 2: Test Local OneSignal Service
async function testLocalOneSignalService() {
    console.log('\n2️⃣ Testing Local OneSignal Service...');
    
    try {
        // Temporarily set environment variables
        process.env.ONESIGNAL_APP_ID = ONESIGNAL_CONFIG.appId;
        process.env.ONESIGNAL_REST_API_KEY = ONESIGNAL_CONFIG.restApiKey;
        
        const oneSignalService = require('./service-app-backend/services/oneSignalService');
        
        console.log('   ✅ OneSignal service loaded successfully');
        
        const testNotification = {
            title: '🧪 Local Service Test',
            body: 'Testing OneSignal service from local backend'
        };
        
        const testData = {
            type: 'local_service_test',
            timestamp: new Date().toISOString()
        };
        
        console.log('   📱 Sending notification via local service...');
        const result = await oneSignalService.sendToAllUsers(testNotification, testData);
        
        if (result.success) {
            console.log('   ✅ Local service test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ Local service test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ Local service error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Test 3: Test Simple Notification Service
async function testSimpleNotificationService() {
    console.log('\n3️⃣ Testing Simple Notification Service...');
    
    try {
        // Set environment variables
        process.env.ONESIGNAL_APP_ID = ONESIGNAL_CONFIG.appId;
        process.env.ONESIGNAL_REST_API_KEY = ONESIGNAL_CONFIG.restApiKey;
        
        const simpleNotificationService = require('./service-app-backend/services/simpleNotificationService');
        
        console.log('   ✅ Simple notification service loaded successfully');
        
        console.log('   📱 Sending test notification...');
        const result = await simpleNotificationService.sendTestNotification(
            '🧪 Simple Service Local Test',
            'Testing the simplified notification service locally'
        );
        
        if (result.success) {
            console.log('   ✅ Simple service test successful!');
            console.log(`      Notification ID: ${result.notificationId}`);
            console.log(`      Recipients: ${result.recipients || 'Unknown'}`);
            return true;
        } else {
            console.log('   ❌ Simple service test failed:');
            console.log(`      Error: ${result.error}`);
            return false;
        }
    } catch (error) {
        console.log('   ❌ Simple service error:');
        console.log(`      ${error.message}`);
        return false;
    }
}

// Test 4: Test Booking Notification
async function testBookingNotification() {
    console.log('\n4️⃣ Testing Booking Notification...');
    
    try {
        // Set environment variables
        process.env.ONESIGNAL_APP_ID = ONESIGNAL_CONFIG.appId;
        process.env.ONESIGNAL_REST_API_KEY = ONESIGNAL_CONFIG.restApiKey;
        
        const simpleNotificationService = require('./service-app-backend/services/simpleNotificationService');
        
        // Mock booking
        const mockBooking = {
            _id: 'local_test_' + Date.now(),
            serviceType: 'ac_repair',
            customerName: 'Local Test Customer',
            customerPhone: '9876543210',
            customerAddress: 'Test Address, Local City',
            preferredDate: new Date(),
            preferredTime: '10:00',
            status: 'pending',
            paymentAmount: 800
        };
        
        console.log('   📱 Sending new booking notification...');
        const result = await simpleNotificationService.sendNewBookingNotification(mockBooking);
        
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

// Main test runner
async function runSimpleLocalTests() {
    console.log('🚀 Starting Simple Local Tests...\n');
    
    const results = {
        directOneSignal: false,
        localOneSignalService: false,
        simpleNotificationService: false,
        bookingNotification: false
    };
    
    // Run tests
    results.directOneSignal = await testDirectOneSignal();
    results.localOneSignalService = await testLocalOneSignalService();
    results.simpleNotificationService = await testSimpleNotificationService();
    results.bookingNotification = await testBookingNotification();
    
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
    
    if (passed >= 3) {
        console.log('\n🎉 Local notification system is working!');
        console.log('\n📱 Expected Results:');
        console.log(`   - You should have received ${passed} notifications on your device`);
        console.log('   - Each notification should have different titles and content');
        console.log('   - All notifications should appear in your notification tray');
        
        console.log('\n✅ Ready for Production:');
        console.log('   1. The notification system works locally');
        console.log('   2. You can deploy the changes to production');
        console.log('   3. After deployment, test with Flutter app');
        
    } else {
        console.log('\n⚠️ Some tests failed. Check the errors above.');
    }
    
    console.log('\n🔧 Next Steps:');
    console.log('   1. If you received notifications: Deploy to production');
    console.log('   2. Test Flutter app after deployment');
    console.log('   3. Create a booking to test real-time notifications');
}

// Run the tests
runSimpleLocalTests().catch(error => {
    console.error('\n❌ Test error:', error);
});