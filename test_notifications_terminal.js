const https = require('https');

// OneSignal Configuration from your .env
const ONESIGNAL_APP_ID = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
const ONESIGNAL_REST_API_KEY = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
const BACKEND_URL = 'service-app-backend-6jpw.onrender.com';

console.log('🔔 OneSignal Notification Terminal Test');
console.log('=====================================');
console.log(`📱 App ID: ${ONESIGNAL_APP_ID}`);
console.log(`🌐 Backend: https://${BACKEND_URL}`);
console.log('');

/**
 * Test OneSignal App Info
 */
function testOneSignalAppInfo() {
    return new Promise((resolve) => {
        console.log('📱 Testing OneSignal App Info...');
        
        const options = {
            hostname: 'onesignal.com',
            port: 443,
            path: `/api/v1/apps/${ONESIGNAL_APP_ID}`,
            method: 'GET',
            headers: {
                'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
                'Content-Type': 'application/json'
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
                        console.log('✅ OneSignal App Info Retrieved Successfully!');
                        console.log(`   📱 App Name: ${response.name}`);
                        console.log(`   👥 Total Users: ${response.players || 0}`);
                        console.log(`   📧 Messageable Users: ${response.messageable_players || 0}`);
                        console.log(`   📅 Last Updated: ${response.updated_at}`);
                        console.log('');
                        resolve({ success: true, data: response });
                    } else {
                        console.log('❌ OneSignal App Info Error:');
                        console.log(`   📄 Response: ${JSON.stringify(response, null, 2)}`);
                        console.log('');
                        resolve({ success: false, error: response });
                    }
                } catch (error) {
                    console.log('❌ Error parsing OneSignal app info response:', error.message);
                    console.log(`   📄 Raw response: ${data}`);
                    console.log('');
                    resolve({ success: false, error: error.message });
                }
            });
        });

        req.on('error', (error) => {
            console.log('❌ OneSignal app info request error:', error.message);
            console.log('');
            resolve({ success: false, error: error.message });
        });

        req.end();
    });
}

/**
 * Send Test Notification via OneSignal Direct API
 */
function sendDirectOneSignalNotification() {
    return new Promise((resolve) => {
        console.log('📤 Sending Direct OneSignal Notification...');
        
        const message = {
            app_id: ONESIGNAL_APP_ID,
            included_segments: ['All'], // Send to all users
            headings: { en: '🧪 Terminal Test Notification' },
            contents: { en: 'This notification was sent directly from the terminal test script!' },
            data: {
                type: 'terminal_test',
                timestamp: new Date().toISOString(),
                source: 'terminal_script'
            },
            android_sound: 'notification',
            ios_sound: 'default',
            small_icon: 'ic_notification',
            large_icon: 'ic_launcher'
        };

        const postData = JSON.stringify(message);

        const options = {
            hostname: 'onesignal.com',
            port: 443,
            path: '/api/v1/notifications',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
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
                        console.log('✅ Direct OneSignal Notification Sent Successfully!');
                        console.log(`   📧 Notification ID: ${response.id}`);
                        console.log(`   👥 Recipients: ${response.recipients || 'Unknown'}`);
                        console.log(`   📊 Response: ${JSON.stringify(response, null, 2)}`);
                        console.log('');
                        resolve({ success: true, data: response });
                    } else {
                        console.log('❌ Direct OneSignal Notification Error:');
                        console.log(`   📄 Response: ${JSON.stringify(response, null, 2)}`);
                        
                        if (response.errors) {
                            console.log('   🚨 Errors:');
                            response.errors.forEach((error, index) => {
                                console.log(`      ${index + 1}. ${error}`);
                            });
                        }
                        console.log('');
                        resolve({ success: false, error: response });
                    }
                } catch (error) {
                    console.log('❌ Error parsing OneSignal notification response:', error.message);
                    console.log(`   📄 Raw response: ${data}`);
                    console.log('');
                    resolve({ success: false, error: error.message });
                }
            });
        });

        req.on('error', (error) => {
            console.log('❌ OneSignal notification request error:', error.message);
            console.log('');
            resolve({ success: false, error: error.message });
        });

        req.write(postData);
        req.end();
    });
}

/**
 * Test Backend Notification Endpoint
 */
function testBackendNotificationEndpoint() {
    return new Promise((resolve) => {
        console.log('🌐 Testing Backend Notification Endpoint...');
        
        const postData = JSON.stringify({
            title: '🧪 Backend Terminal Test',
            message: 'This notification was sent via the backend API from terminal!',
            type: 'terminal_backend_test',
            recipient: 'all',
            priority: 'high'
        });

        const options = {
            hostname: BACKEND_URL,
            port: 443,
            path: '/api/notifications/test',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'TerminalTestScript/1.0',
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
                        console.log('✅ Backend Notification Endpoint Test Successful!');
                        console.log(`   📧 Message: ${response.message}`);
                        if (response.notification) {
                            console.log(`   🆔 Notification ID: ${response.notification.id || 'N/A'}`);
                        }
                        if (response.oneSignalResult) {
                            console.log(`   📡 OneSignal ID: ${response.oneSignalResult.notificationId || 'N/A'}`);
                            console.log(`   👥 Recipients: ${response.oneSignalResult.recipients || 'N/A'}`);
                        }
                        console.log('');
                        resolve({ success: true, data: response });
                    } else {
                        console.log('❌ Backend Notification Endpoint Error:');
                        console.log(`   📄 Message: ${response.message || 'Unknown error'}`);
                        console.log(`   📄 Response: ${JSON.stringify(response, null, 2)}`);
                        console.log('');
                        resolve({ success: false, error: response });
                    }
                } catch (error) {
                    console.log('❌ Error parsing backend notification response:', error.message);
                    console.log(`   📄 Raw response: ${data}`);
                    console.log('');
                    resolve({ success: false, error: error.message });
                }
            });
        });

        req.on('error', (error) => {
            console.log('❌ Backend notification request error:', error.message);
            console.log('');
            resolve({ success: false, error: error.message });
        });

        req.write(postData);
        req.end();
    });
}

/**
 * Test Backend Health
 */
function testBackendHealth() {
    return new Promise((resolve) => {
        console.log('🏥 Testing Backend Health...');
        
        const options = {
            hostname: BACKEND_URL,
            port: 443,
            path: '/health',
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'User-Agent': 'TerminalTestScript/1.0'
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
                    
                    if (response.status === 'OK') {
                        console.log('✅ Backend Health Check Successful!');
                        console.log(`   🏥 Status: ${response.status}`);
                        console.log(`   ⏱️  Uptime: ${Math.floor(response.uptime / 3600)}h ${Math.floor((response.uptime % 3600) / 60)}m`);
                        console.log(`   📅 Timestamp: ${response.timestamp}`);
                        console.log('');
                        resolve({ success: true, data: response });
                    } else {
                        console.log('❌ Backend Health Check Failed:');
                        console.log(`   📄 Response: ${JSON.stringify(response, null, 2)}`);
                        console.log('');
                        resolve({ success: false, error: response });
                    }
                } catch (error) {
                    console.log('❌ Error parsing backend health response:', error.message);
                    console.log(`   📄 Raw response: ${data}`);
                    console.log('');
                    resolve({ success: false, error: error.message });
                }
            });
        });

        req.on('error', (error) => {
            console.log('❌ Backend health request error:', error.message);
            console.log('');
            resolve({ success: false, error: error.message });
        });

        req.end();
    });
}

/**
 * Run All Tests
 */
async function runAllTests() {
    console.log('🚀 Starting Comprehensive Notification Tests...');
    console.log('');

    const results = {
        backendHealth: false,
        oneSignalAppInfo: false,
        directNotification: false,
        backendNotification: false
    };

    try {
        // Test 1: Backend Health
        const healthResult = await testBackendHealth();
        results.backendHealth = healthResult.success;

        // Test 2: OneSignal App Info
        const appInfoResult = await testOneSignalAppInfo();
        results.oneSignalAppInfo = appInfoResult.success;

        // Test 3: Direct OneSignal Notification
        const directResult = await sendDirectOneSignalNotification();
        results.directNotification = directResult.success;

        // Test 4: Backend Notification Endpoint
        const backendResult = await testBackendNotificationEndpoint();
        results.backendNotification = backendResult.success;

    } catch (error) {
        console.log('❌ Test execution error:', error.message);
    }

    // Summary
    console.log('📊 TEST SUMMARY');
    console.log('===============');
    console.log(`🏥 Backend Health: ${results.backendHealth ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`📱 OneSignal App Info: ${results.oneSignalAppInfo ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`📤 Direct OneSignal Notification: ${results.directNotification ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`🌐 Backend Notification Endpoint: ${results.backendNotification ? '✅ PASS' : '❌ FAIL'}`);
    console.log('');

    const passCount = Object.values(results).filter(Boolean).length;
    const totalTests = Object.keys(results).length;

    if (passCount === totalTests) {
        console.log('🎉 ALL TESTS PASSED! Your notification system is working perfectly!');
        console.log('');
        console.log('📱 Next Steps:');
        console.log('   1. Check your device for the test notifications');
        console.log('   2. Build and test your Flutter app');
        console.log('   3. Verify notifications work in the app');
    } else {
        console.log(`⚠️  ${passCount}/${totalTests} tests passed. Some issues need attention.`);
        console.log('');
        console.log('🔧 Troubleshooting:');
        if (!results.backendHealth) {
            console.log('   - Backend health failed: Check if your backend is running');
        }
        if (!results.oneSignalAppInfo) {
            console.log('   - OneSignal app info failed: Check your App ID and REST API key');
        }
        if (!results.directNotification) {
            console.log('   - Direct notification failed: Check OneSignal configuration');
        }
        if (!results.backendNotification) {
            console.log('   - Backend notification failed: Check notification endpoint');
        }
    }

    console.log('');
    console.log('📞 Support:');
    console.log('   - OneSignal Dashboard: https://onesignal.com/');
    console.log('   - Backend Health: https://service-app-backend-6jpw.onrender.com/health');
    console.log('   - App ID: f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d');
}

// Run the tests
runAllTests().catch(error => {
    console.error('❌ Fatal error running tests:', error);
    process.exit(1);
});