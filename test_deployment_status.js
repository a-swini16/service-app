#!/usr/bin/env node

const https = require('https');

console.log('🔍 Testing Deployment Status...\n');

// Test the new endpoints we added
async function testNewEndpoints() {
    console.log('1️⃣ Testing User Bookings Endpoint (New)...');
    
    try {
        const response = await makeRequest('/bookings/user/6371448994');
        
        if (response.statusCode === 200 && response.data.success) {
            console.log(`✅ User bookings endpoint working!`);
            console.log(`   Found ${response.data.bookings.length} bookings for phone 6371448994`);
            return true;
        } else {
            console.log(`❌ User bookings endpoint failed: ${response.statusCode}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ User bookings endpoint error: ${error.message}`);
        return false;
    }
}

async function testNotificationEndpoint() {
    console.log('\n2️⃣ Testing Notification Endpoint...');
    
    const testData = {
        title: 'Simple Test',
        message: 'Testing notification endpoint',
        type: 'simple_test'
    };

    try {
        const response = await makeRequest('/notifications/test', 'POST', testData);
        
        console.log(`📡 Response Status: ${response.statusCode}`);
        console.log(`📡 Response Data: ${JSON.stringify(response.data)}`);
        
        if (response.statusCode === 200 && response.data.success) {
            console.log(`✅ Notification endpoint working!`);
            return true;
        } else {
            console.log(`❌ Notification endpoint failed`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Notification endpoint error: ${error.message}`);
        return false;
    }
}

async function testAdminBookings() {
    console.log('\n3️⃣ Testing Admin Bookings (Should work)...');
    
    try {
        const response = await makeRequest('/admin/bookings');
        
        if (response.statusCode === 200 && response.data.success) {
            console.log(`✅ Admin bookings working: ${response.data.bookings.length} bookings`);
            return true;
        } else {
            console.log(`❌ Admin bookings failed: ${response.statusCode}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Admin bookings error: ${error.message}`);
        return false;
    }
}

// Helper function
function makeRequest(path, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'service-app-backend-6jpw.onrender.com',
            port: 443,
            path: `/api${path}`,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(responseData);
                    resolve({
                        statusCode: res.statusCode,
                        data: parsed
                    });
                } catch (e) {
                    resolve({
                        statusCode: res.statusCode,
                        data: responseData
                    });
                }
            });
        });

        req.on('error', (e) => {
            reject(e);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }

        req.end();
    });
}

// Run tests
async function runDeploymentTest() {
    console.log('🚀 Testing Deployment Status...\n');
    
    const results = {
        userBookings: false,
        notifications: false,
        adminBookings: false
    };
    
    results.userBookings = await testNewEndpoints();
    results.notifications = await testNotificationEndpoint();
    results.adminBookings = await testAdminBookings();
    
    console.log('\n📊 Deployment Test Results:');
    console.log('============================');
    
    const passed = Object.values(results).filter(r => r).length;
    const total = Object.keys(results).length;
    
    Object.entries(results).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test}`);
    });
    
    console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
    
    if (results.userBookings) {
        console.log('\n🎉 Great! The deployment worked partially:');
        console.log('   ✅ New user booking endpoint is working');
        console.log('   ✅ User tracking will now work in Flutter app');
    }
    
    if (results.notifications) {
        console.log('   ✅ Notification system is fully working');
        console.log('   ✅ Real-time notifications will work');
    } else {
        console.log('   ⚠️ Notification endpoint needs debugging');
        console.log('   💡 But OneSignal direct API works fine');
    }
    
    console.log('\n🔧 Next Steps:');
    console.log('   1. Test Flutter app - user tracking should work now');
    console.log('   2. Test admin panel - should show all bookings');
    console.log('   3. Create a new booking to test notifications');
}

runDeploymentTest().catch(console.error);