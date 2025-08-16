#!/usr/bin/env node

/**
 * Flutter Notification Integration Test Runner
 * Tests the notification system from Flutter perspective
 */

const { spawn } = require('child_process');
const https = require('https');

console.log('🧪 Flutter Notification Integration Test\n');

// Test 1: Run Flutter tests
async function runFlutterTests() {
    console.log('1️⃣ Running Flutter Integration Tests...');
    
    return new Promise((resolve) => {
        const flutterTest = spawn('flutter', ['test', 'test/notification_integration_test.dart', '--verbose'], {
            stdio: 'inherit',
            shell: true
        });
        
        flutterTest.on('close', (code) => {
            if (code === 0) {
                console.log('✅ Flutter tests completed successfully');
                resolve(true);
            } else {
                console.log(`❌ Flutter tests failed with code ${code}`);
                resolve(false);
            }
        });
        
        flutterTest.on('error', (error) => {
            console.log(`❌ Flutter test error: ${error.message}`);
            resolve(false);
        });
    });
}

// Test 2: Test notification endpoint directly
async function testNotificationEndpoint() {
    console.log('\n2️⃣ Testing Notification Endpoint Directly...');
    
    const testData = {
        title: '🧪 Terminal → Flutter Test',
        message: 'Testing notification from terminal for Flutter app verification',
        type: 'terminal_flutter_test'
    };

    return new Promise((resolve) => {
        const postData = JSON.stringify(testData);

        const options = {
            hostname: 'service-app-backend-6jpw.onrender.com',
            port: 443,
            path: '/api/notifications/test',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
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
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('✅ Notification endpoint test passed!');
                        console.log(`   Notification ID: ${response.notification?.id || 'N/A'}`);
                        console.log(`   Title: ${response.notification?.title || 'N/A'}`);
                        resolve(true);
                    } else {
                        console.log('❌ Notification endpoint test failed:');
                        console.log(`   Status: ${res.statusCode}`);
                        console.log(`   Error: ${response.message || 'Unknown error'}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log(`❌ Response parse error: ${error.message}`);
                    console.log(`   Raw response: ${data}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log(`❌ Request error: ${error.message}`);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test 3: Test booking simulation
async function testBookingSimulation() {
    console.log('\n3️⃣ Testing Booking Creation Simulation...');
    
    const bookingNotification = {
        title: '🆕 New Booking Alert!',
        message: 'New AC Repair booking from Test Customer at Test Address. Scheduled for tomorrow at 10:00 AM. Amount: ₹800',
        type: 'booking_simulation_test'
    };

    return new Promise((resolve) => {
        const postData = JSON.stringify(bookingNotification);

        const options = {
            hostname: 'service-app-backend-6jpw.onrender.com',
            port: 443,
            path: '/api/notifications/test',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
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
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('✅ Booking simulation test passed!');
                        console.log(`   This simulates what happens when a user creates a booking`);
                        console.log(`   Admin should receive this notification in real-time`);
                        console.log(`   Notification ID: ${response.notification?.id || 'N/A'}`);
                        resolve(true);
                    } else {
                        console.log('❌ Booking simulation test failed:');
                        console.log(`   Status: ${res.statusCode}`);
                        console.log(`   Error: ${response.message || 'Unknown error'}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log(`❌ Response parse error: ${error.message}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log(`❌ Request error: ${error.message}`);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test 4: Test OneSignal direct (we know this works)
async function testOneSignalDirect() {
    console.log('\n4️⃣ Testing OneSignal Direct API...');
    
    const appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
    const restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
    
    const message = {
        app_id: appId,
        included_segments: ['All'],
        headings: { en: '🧪 Flutter Integration Verification' },
        contents: { en: 'Final test - if you receive this, Flutter notification integration is ready!' },
        data: {
            type: 'flutter_integration_verification',
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
                'Authorization': `Basic ${restApiKey}`,
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
                        console.log('✅ OneSignal direct test passed!');
                        console.log(`   Notification ID: ${response.id}`);
                        console.log(`   Recipients: ${response.recipients || 'Unknown'}`);
                        resolve(true);
                    } else {
                        console.log('❌ OneSignal direct test failed:');
                        console.log(`   Error: ${JSON.stringify(response.errors || response)}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log(`❌ Response parse error: ${error.message}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log(`❌ Request error: ${error.message}`);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Main test runner
async function runFlutterNotificationTests() {
    console.log('🚀 Starting Flutter Notification Integration Tests...\n');
    
    const results = {
        flutterTests: false,
        notificationEndpoint: false,
        bookingSimulation: false,
        oneSignalDirect: false
    };
    
    // Run all tests
    results.flutterTests = await runFlutterTests();
    results.notificationEndpoint = await testNotificationEndpoint();
    results.bookingSimulation = await testBookingSimulation();
    results.oneSignalDirect = await testOneSignalDirect();
    
    // Summary
    console.log('\n📊 Flutter Notification Integration Results:');
    console.log('============================================');
    
    const passed = Object.values(results).filter(r => r).length;
    const total = Object.keys(results).length;
    
    Object.entries(results).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test}`);
    });
    
    console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
    
    if (passed >= 3) {
        console.log('\n🎉 Flutter notification integration is working!');
        console.log('\n📱 Expected Results:');
        console.log(`   - You should have received ${passed} notifications on your device`);
        console.log('   - Each notification should have different content');
        console.log('   - The last notification confirms Flutter integration is ready');
        
        console.log('\n✅ Ready for Real Testing:');
        console.log('   1. Build and install the Flutter APK');
        console.log('   2. Create a booking in the app');
        console.log('   3. Admin should receive notification immediately');
        console.log('   4. Test status changes (accept/reject booking)');
        console.log('   5. User should receive status update notifications');
        
    } else {
        console.log('\n⚠️ Some tests failed. Check the errors above.');
        console.log('\n🔧 Common Issues:');
        console.log('   - Backend deployment might not be complete');
        console.log('   - Network connectivity issues');
        console.log('   - OneSignal configuration problems');
    }
    
    console.log('\n🔧 Next Steps:');
    console.log('   1. If notifications work: Build Flutter APK and test real booking flow');
    console.log('   2. If notifications fail: Check backend deployment status');
    console.log('   3. Test admin panel and user tracking in Flutter app');
    
    console.log('\n📋 Integration Test Summary:');
    console.log('   - Flutter Tests: ' + (results.flutterTests ? 'Working ✅' : 'Failed ❌'));
    console.log('   - Backend Notifications: ' + (results.notificationEndpoint ? 'Working ✅' : 'Failed ❌'));
    console.log('   - Booking Simulation: ' + (results.bookingSimulation ? 'Working ✅' : 'Failed ❌'));
    console.log('   - OneSignal Direct: ' + (results.oneSignalDirect ? 'Working ✅' : 'Failed ❌'));
}

// Run the tests
runFlutterNotificationTests().catch(error => {
    console.error('\n❌ Test runner error:', error);
    process.exit(1);
});