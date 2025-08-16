#!/usr/bin/env node

const https = require('https');

console.log('🔔 Testing Notification System...\n');

// Test OneSignal directly
async function testOneSignalDirect() {
    console.log('1️⃣ Testing OneSignal Direct API...');
    
    const appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
    const restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
    
    const message = {
        app_id: appId,
        included_segments: ['All'],
        headings: { en: '🧪 Direct OneSignal Test' },
        contents: { en: 'This is a direct test of OneSignal API from Node.js' },
        data: {
            type: 'direct_test',
            timestamp: new Date().toISOString()
        }
    };

    return new Promise((resolve, reject) => {
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
                        console.log(`✅ OneSignal Direct Test Success!`);
                        console.log(`   Notification ID: ${response.id}`);
                        console.log(`   Recipients: ${response.recipients || 'Unknown'}`);
                        resolve(true);
                    } else {
                        console.log(`❌ OneSignal Direct Test Failed:`);
                        console.log(`   Error: ${JSON.stringify(response.errors || response)}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log(`❌ OneSignal Response Parse Error: ${error.message}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log(`❌ OneSignal Request Error: ${error.message}`);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test backend notification endpoint
async function testBackendNotification() {
    console.log('\n2️⃣ Testing Backend Notification Endpoint...');
    
    const testData = {
        title: '🧪 Backend Notification Test',
        message: 'This is a test notification from the backend API',
        type: 'backend_test'
    };

    return new Promise((resolve, reject) => {
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
                    
                    if (response.success) {
                        console.log(`✅ Backend Notification Test Success!`);
                        console.log(`   Message: ${response.message}`);
                        console.log(`   Notification ID: ${response.notification?.id || 'N/A'}`);
                        resolve(true);
                    } else {
                        console.log(`❌ Backend Notification Test Failed:`);
                        console.log(`   Error: ${response.message}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log(`❌ Backend Response Parse Error: ${error.message}`);
                    console.log(`   Raw Response: ${data}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.log(`❌ Backend Request Error: ${error.message}`);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test booking creation notification
async function testBookingNotification() {
    console.log('\n3️⃣ Testing Booking Creation Notification...');
    
    // This would require authentication, so we'll just check if the endpoint exists
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'service-app-backend-6jpw.onrender.com',
            port: 443,
            path: '/api/bookings',
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            if (res.statusCode === 401) {
                console.log(`✅ Booking endpoint exists (requires auth)`);
                console.log(`   Status: ${res.statusCode} (Expected for unauthenticated request)`);
                resolve(true);
            } else {
                console.log(`⚠️ Booking endpoint status: ${res.statusCode}`);
                resolve(false);
            }
        });

        req.on('error', (error) => {
            console.log(`❌ Booking endpoint error: ${error.message}`);
            resolve(false);
        });

        req.end();
    });
}

// Main test runner
async function runNotificationTests() {
    console.log('🚀 Starting Notification System Tests...\n');
    
    const results = {
        oneSignalDirect: false,
        backendNotification: false,
        bookingEndpoint: false
    };
    
    // Run tests
    results.oneSignalDirect = await testOneSignalDirect();
    results.backendNotification = await testBackendNotification();
    results.bookingEndpoint = await testBookingNotification();
    
    // Summary
    console.log('\n📊 Notification Test Results:');
    console.log('==============================');
    
    const passed = Object.values(results).filter(r => r).length;
    const total = Object.keys(results).length;
    
    Object.entries(results).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test}`);
    });
    
    console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
    
    if (results.oneSignalDirect) {
        console.log('\n🎉 OneSignal is working! Check your device for notifications.');
        console.log('\n💡 If you received the notification:');
        console.log('   1. OneSignal configuration is correct');
        console.log('   2. Your device is properly subscribed');
        console.log('   3. The issue is in the backend notification flow');
    } else {
        console.log('\n⚠️ OneSignal direct test failed. Check:');
        console.log('   1. OneSignal App ID and API Key');
        console.log('   2. Device subscription status');
        console.log('   3. Network connectivity');
    }
    
    if (results.backendNotification) {
        console.log('\n✅ Backend notification endpoint is working');
    } else {
        console.log('\n❌ Backend notification endpoint needs fixing');
    }
    
    console.log('\n🔧 Next Steps:');
    console.log('   1. Check your device for test notifications');
    console.log('   2. If notifications work, the issue is in booking workflow');
    console.log('   3. If notifications don\'t work, check OneSignal setup');
}

// Run the tests
runNotificationTests().catch(console.error);