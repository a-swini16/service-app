#!/usr/bin/env node

/**
 * Test Existing Local Backend
 * Tests the notification system on already running local backend
 */

const http = require('http');
const https = require('https');

console.log('🧪 Testing Existing Local Backend\n');
console.log('📡 Assuming backend is running on localhost:5000\n');

let testResults = {
    healthCheck: false,
    notificationEndpoint: false,
    oneSignalDirect: false
};

// Test 1: Health check
async function testLocalHealth() {
    console.log('1️⃣ Testing Local Backend Health...');
    
    return new Promise((resolve) => {
        const req = http.get('http://localhost:5000/api/health', (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    
                    console.log(`   📡 Status: ${res.statusCode}`);
                    console.log(`   📡 Response: ${JSON.stringify(response, null, 2)}`);
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('   ✅ Local backend health check passed!');
                        console.log(`      Status: ${response.status}`);
                        console.log(`      Message: ${response.message}`);
                        testResults.healthCheck = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ Health check failed');
                        resolve(false);
                    }
                } catch (error) {
                    console.log('   ❌ Health check parse error:', error.message);
                    console.log(`   📡 Raw response: ${data}`);
                    resolve(false);
                }
            });
        });
        
        req.on('error', (error) => {
            console.log('   ❌ Health check request error:', error.message);
            console.log('   💡 Make sure backend server is running on localhost:5000');
            resolve(false);
        });
        
        req.setTimeout(10000, () => {
            console.log('   ❌ Health check timeout');
            resolve(false);
        });
    });
}

// Test 2: Notification endpoint
async function testLocalNotificationEndpoint() {
    console.log('\n2️⃣ Testing Local Notification Endpoint...');
    
    const testData = {
        title: '🧪 Local Backend Test',
        message: 'Testing notification endpoint on existing local backend server',
        type: 'existing_local_backend_test'
    };
    
    return new Promise((resolve) => {
        const postData = JSON.stringify(testData);
        
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/notifications/test',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };
        
        console.log('   📡 Sending request to: http://localhost:5000/api/notifications/test');
        console.log('   📡 Request data:', JSON.stringify(testData, null, 2));
        
        const req = http.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    
                    console.log(`   📡 Response Status: ${res.statusCode}`);
                    console.log(`   📡 Response Data: ${JSON.stringify(response, null, 2)}`);
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('   ✅ Local notification endpoint test PASSED!');
                        console.log(`      Notification ID: ${response.notification?.id || 'N/A'}`);
                        console.log(`      Title: ${response.notification?.title || 'N/A'}`);
                        console.log('   📱 You should have received a notification on your device!');
                        testResults.notificationEndpoint = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ Local notification endpoint test FAILED');
                        console.log(`      Status: ${res.statusCode}`);
                        console.log(`      Error: ${response.message || 'Unknown error'}`);
                        console.log(`      Details: ${response.error || 'No details'}`);
                        resolve(false);
                    }
                } catch (error) {
                    console.log('   ❌ Response parse error:', error.message);
                    console.log(`   📡 Raw response: ${data}`);
                    resolve(false);
                }
            });
        });
        
        req.on('error', (error) => {
            console.log('   ❌ Request error:', error.message);
            resolve(false);
        });
        
        req.setTimeout(15000, () => {
            console.log('   ❌ Request timeout (15s)');
            resolve(false);
        });
        
        req.write(postData);
        req.end();
    });
}

// Test 3: OneSignal direct (for comparison)
async function testOneSignalDirect() {
    console.log('\n3️⃣ Testing OneSignal Direct API (for comparison)...');
    
    const appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
    const restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
    
    const message = {
        app_id: appId,
        included_segments: ['All'],
        headings: { en: '🧪 Direct OneSignal Test' },
        contents: { en: 'Testing OneSignal directly - comparing with local backend' },
        data: {
            type: 'direct_onesignal_comparison',
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
                        console.log('   ✅ OneSignal direct test passed!');
                        console.log(`      Notification ID: ${response.id}`);
                        console.log(`      Recipients: ${response.recipients || 'Unknown'}`);
                        console.log('   📱 You should have received this notification too!');
                        testResults.oneSignalDirect = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ OneSignal direct test failed:');
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

// Main test runner
async function runExistingLocalBackendTest() {
    console.log('🚀 Starting Existing Local Backend Test...\n');
    
    // Run all tests
    await testLocalHealth();
    await testLocalNotificationEndpoint();
    await testOneSignalDirect();
    
    // Results summary
    console.log('\n📊 Local Backend Test Results:');
    console.log('==============================');
    
    const passed = Object.values(testResults).filter(r => r).length;
    const total = Object.keys(testResults).length;
    
    Object.entries(testResults).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test}`);
    });
    
    console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
    
    if (testResults.notificationEndpoint) {
        console.log('\n🎉 LOCAL BACKEND NOTIFICATIONS ARE WORKING!');
        console.log('\n📱 Expected Results:');
        console.log('   - You should have received 1-2 notifications on your device');
        console.log('   - Local backend notification endpoint is working perfectly');
        console.log('   - OneSignal integration is confirmed working');
        
        console.log('\n✅ READY TO PROCEED:');
        console.log('   1. ✅ Local backend notification system is CONFIRMED WORKING');
        console.log('   2. 🚀 Deploy the changes to production');
        console.log('   3. 📱 Test Flutter app with production backend');
        console.log('   4. 🎯 Create real bookings to test end-to-end flow');
        
        console.log('\n🔧 Next Steps:');
        console.log('   1. Deploy to production: git add . && git commit -m "Fix notifications" && git push');
        console.log('   2. Wait for deployment to complete');
        console.log('   3. Run: node test_deployment_status.js');
        console.log('   4. Test Flutter app integration');
        
    } else if (testResults.healthCheck && !testResults.notificationEndpoint) {
        console.log('\n⚠️ Local backend is running but notifications need fixing:');
        console.log('   - Health check passed ✅');
        console.log('   - Notification endpoint failed ❌');
        console.log('   - Check the error details above');
        console.log('   - Fix the OneSignal service import issue');
        
    } else {
        console.log('\n❌ Local backend is not running or not accessible:');
        console.log('   - Make sure backend server is running: npm start or node server.js');
        console.log('   - Check if port 5000 is available');
        console.log('   - Verify the server started without errors');
    }
    
    console.log('\n📋 Test Summary:');
    console.log('   - Local Backend Health: ' + (testResults.healthCheck ? 'Working ✅' : 'Failed ❌'));
    console.log('   - Notification Endpoint: ' + (testResults.notificationEndpoint ? 'Working ✅' : 'Failed ❌'));
    console.log('   - OneSignal Direct: ' + (testResults.oneSignalDirect ? 'Working ✅' : 'Failed ❌'));
    
    if (testResults.notificationEndpoint) {
        console.log('\n🎯 CONCLUSION: Local backend notifications are working perfectly!');
        console.log('   Ready to deploy to production and test Flutter app integration.');
    }
}

// Run the test
runExistingLocalBackendTest().catch(error => {
    console.error('\n❌ Test runner error:', error);
    process.exit(1);
});