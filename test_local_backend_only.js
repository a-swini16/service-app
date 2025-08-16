#!/usr/bin/env node

/**
 * Local Backend Only Test
 * Tests the notification system on local backend server
 */

const { spawn } = require('child_process');
const https = require('https');
const http = require('http');

console.log('🧪 Local Backend Notification Test\n');

let backendProcess = null;
let testResults = {
    serverStart: false,
    healthCheck: false,
    notificationEndpoint: false,
    oneSignalIntegration: false
};

// Step 1: Start local backend server
async function startLocalBackend() {
    console.log('1️⃣ Starting Local Backend Server...');
    
    return new Promise((resolve) => {
        // Start the backend server
        backendProcess = spawn('node', ['server.js'], {
            cwd: './service-app-backend',
            stdio: ['pipe', 'pipe', 'pipe'],
            shell: true
        });
        
        let serverOutput = '';
        
        backendProcess.stdout.on('data', (data) => {
            const output = data.toString();
            serverOutput += output;
            console.log('   📡 Server:', output.trim());
            
            // Check if server started successfully
            if (output.includes('Server running on port') || output.includes('listening on port')) {
                console.log('   ✅ Local backend server started successfully');
                testResults.serverStart = true;
                setTimeout(() => resolve(true), 2000); // Wait 2 seconds for full startup
            }
        });
        
        backendProcess.stderr.on('data', (data) => {
            const error = data.toString();
            console.log('   ⚠️ Server Error:', error.trim());
        });
        
        backendProcess.on('error', (error) => {
            console.log('   ❌ Failed to start backend server:', error.message);
            resolve(false);
        });
        
        // Timeout after 30 seconds
        setTimeout(() => {
            if (!testResults.serverStart) {
                console.log('   ❌ Server startup timeout (30s)');
                resolve(false);
            }
        }, 30000);
    });
}

// Step 2: Test local backend health
async function testLocalHealth() {
    console.log('\n2️⃣ Testing Local Backend Health...');
    
    return new Promise((resolve) => {
        const req = http.get('http://localhost:5000/api/health', (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('   ✅ Local backend health check passed');
                        console.log(`      Status: ${response.status}`);
                        console.log(`      Message: ${response.message}`);
                        testResults.healthCheck = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ Health check failed:', response);
                        resolve(false);
                    }
                } catch (error) {
                    console.log('   ❌ Health check parse error:', error.message);
                    resolve(false);
                }
            });
        });
        
        req.on('error', (error) => {
            console.log('   ❌ Health check request error:', error.message);
            resolve(false);
        });
        
        req.setTimeout(10000, () => {
            console.log('   ❌ Health check timeout');
            resolve(false);
        });
    });
}

// Step 3: Test local notification endpoint
async function testLocalNotificationEndpoint() {
    console.log('\n3️⃣ Testing Local Notification Endpoint...');
    
    const testData = {
        title: '🧪 Local Backend Test',
        message: 'Testing notification endpoint on local backend server',
        type: 'local_backend_test'
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
                        console.log('   ✅ Local notification endpoint test passed!');
                        console.log(`      Notification ID: ${response.notification?.id || 'N/A'}`);
                        testResults.notificationEndpoint = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ Local notification endpoint test failed');
                        console.log(`      Error: ${response.message || 'Unknown error'}`);
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
            console.log('   ❌ Request timeout');
            resolve(false);
        });
        
        req.write(postData);
        req.end();
    });
}

// Step 4: Test OneSignal integration directly
async function testOneSignalIntegration() {
    console.log('\n4️⃣ Testing OneSignal Integration...');
    
    const appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
    const restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
    
    const message = {
        app_id: appId,
        included_segments: ['All'],
        headings: { en: '🧪 Local Backend Integration Test' },
        contents: { en: 'Testing OneSignal from local backend - if you receive this, local backend is working!' },
        data: {
            type: 'local_backend_integration_test',
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
                        console.log('   ✅ OneSignal integration test passed!');
                        console.log(`      Notification ID: ${response.id}`);
                        console.log(`      Recipients: ${response.recipients || 'Unknown'}`);
                        testResults.oneSignalIntegration = true;
                        resolve(true);
                    } else {
                        console.log('   ❌ OneSignal integration test failed:');
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

// Step 5: Stop local backend
function stopLocalBackend() {
    console.log('\n5️⃣ Stopping Local Backend Server...');
    
    if (backendProcess) {
        backendProcess.kill('SIGTERM');
        console.log('   ✅ Local backend server stopped');
    }
}

// Main test runner
async function runLocalBackendTest() {
    console.log('🚀 Starting Local Backend Notification Test...\n');
    
    try {
        // Step 1: Start local backend
        const serverStarted = await startLocalBackend();
        if (!serverStarted) {
            console.log('\n❌ Failed to start local backend server');
            return;
        }
        
        // Step 2: Test health
        await testLocalHealth();
        
        // Step 3: Test notification endpoint
        await testLocalNotificationEndpoint();
        
        // Step 4: Test OneSignal integration
        await testOneSignalIntegration();
        
    } catch (error) {
        console.log('\n❌ Test error:', error.message);
    } finally {
        // Step 5: Stop backend
        stopLocalBackend();
    }
    
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
    
    if (passed >= 3) {
        console.log('\n🎉 Local backend notification system is working!');
        console.log('\n📱 Expected Results:');
        console.log('   - You should have received 1-2 notifications on your device');
        console.log('   - Local backend can send notifications successfully');
        console.log('   - OneSignal integration is working');
        
        console.log('\n✅ Ready for Next Steps:');
        console.log('   1. Local backend notification system is confirmed working');
        console.log('   2. Deploy the changes to production');
        console.log('   3. Test Flutter app with production backend');
        console.log('   4. Create real bookings to test end-to-end flow');
        
    } else {
        console.log('\n⚠️ Local backend has issues that need fixing:');
        
        if (!testResults.serverStart) {
            console.log('   - Backend server failed to start');
            console.log('   - Check if port 5000 is available');
            console.log('   - Check if all dependencies are installed');
        }
        
        if (!testResults.healthCheck) {
            console.log('   - Health endpoint not responding');
            console.log('   - Server might not be fully started');
        }
        
        if (!testResults.notificationEndpoint) {
            console.log('   - Notification endpoint has issues');
            console.log('   - Check OneSignal service import');
            console.log('   - Check environment variables');
        }
    }
    
    console.log('\n🔧 Next Steps:');
    if (passed >= 3) {
        console.log('   1. Deploy to production: git add . && git commit && git push');
        console.log('   2. Test production backend with same tests');
        console.log('   3. Test Flutter app integration');
    } else {
        console.log('   1. Fix local backend issues first');
        console.log('   2. Re-run this test until all pass');
        console.log('   3. Then deploy to production');
    }
}

// Handle process termination
process.on('SIGINT', () => {
    console.log('\n\n🛑 Test interrupted by user');
    stopLocalBackend();
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n\n🛑 Test terminated');
    stopLocalBackend();
    process.exit(0);
});

// Run the test
runLocalBackendTest().catch(error => {
    console.error('\n❌ Test runner error:', error);
    stopLocalBackend();
    process.exit(1);
});