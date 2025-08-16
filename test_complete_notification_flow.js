#!/usr/bin/env node

const https = require('https');

console.log('🔔 Testing Complete Notification Flow...\n');

// Test configuration
const BASE_URL = 'service-app-backend-6jpw.onrender.com';
const API_BASE = '/api';

// Helper function to make HTTPS requests
function makeRequest(path, method = 'GET', data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: BASE_URL,
      port: 443,
      path: `${API_BASE}${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers
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
            data: parsed,
            headers: res.headers
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            data: responseData,
            headers: res.headers
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

// Test 1: Simple notification test
async function testSimpleNotification() {
  console.log('1️⃣ Testing Simple Notification Service...');
  
  const testData = {
    title: '🧪 Simple Service Test',
    message: 'Testing the simplified notification service',
    type: 'simple_test'
  };

  try {
    const response = await makeRequest('/notifications/test', 'POST', testData);
    
    if (response.statusCode === 200 && response.data.success) {
      console.log(`✅ Simple notification test passed!`);
      console.log(`   Notification ID: ${response.data.notification?.id || 'N/A'}`);
      console.log(`   Recipients: ${response.data.notification?.recipients || 'Unknown'}`);
      return true;
    } else {
      console.log(`❌ Simple notification test failed:`);
      console.log(`   Status: ${response.statusCode}`);
      console.log(`   Error: ${response.data.message || 'Unknown error'}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Simple notification test error: ${error.message}`);
    return false;
  }
}

// Test 2: Check if booking endpoint exists
async function testBookingEndpoint() {
  console.log('\n2️⃣ Testing Booking Endpoint...');
  
  try {
    const response = await makeRequest('/bookings', 'GET');
    
    if (response.statusCode === 401) {
      console.log(`✅ Booking endpoint exists (requires authentication)`);
      console.log(`   Status: ${response.statusCode} - Expected for unauthenticated request`);
      return true;
    } else if (response.statusCode === 200) {
      console.log(`✅ Booking endpoint accessible`);
      console.log(`   Status: ${response.statusCode}`);
      return true;
    } else {
      console.log(`⚠️ Booking endpoint status: ${response.statusCode}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Booking endpoint error: ${error.message}`);
    return false;
  }
}

// Test 3: Check admin bookings (should work)
async function testAdminBookings() {
  console.log('\n3️⃣ Testing Admin Bookings...');
  
  try {
    const response = await makeRequest('/admin/bookings', 'GET');
    
    if (response.statusCode === 200 && response.data.success) {
      const bookings = response.data.bookings || [];
      console.log(`✅ Admin bookings endpoint working`);
      console.log(`   Total bookings: ${bookings.length}`);
      
      if (bookings.length > 0) {
        const sample = bookings[0];
        console.log(`   Sample booking: ${sample.customerName} - ${sample.serviceType} - ${sample.status}`);
      }
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

// Test 4: Test OneSignal direct (we know this works)
async function testOneSignalDirect() {
  console.log('\n4️⃣ Testing OneSignal Direct...');
  
  const appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
  const restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
  
  const message = {
    app_id: appId,
    included_segments: ['All'],
    headings: { en: '🔄 Complete Flow Test' },
    contents: { en: 'Testing complete notification flow - you should receive this!' },
    data: {
      type: 'complete_flow_test',
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
            console.log(`✅ OneSignal direct test passed!`);
            console.log(`   Notification ID: ${response.id}`);
            resolve(true);
          } else {
            console.log(`❌ OneSignal direct test failed: ${JSON.stringify(response.errors || response)}`);
            resolve(false);
          }
        } catch (error) {
          console.log(`❌ OneSignal response parse error: ${error.message}`);
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.log(`❌ OneSignal request error: ${error.message}`);
      resolve(false);
    });

    req.write(postData);
    req.end();
  });
}

// Main test runner
async function runCompleteNotificationTest() {
  console.log('🚀 Starting Complete Notification Flow Test...\n');
  
  const results = {
    simpleNotification: false,
    bookingEndpoint: false,
    adminBookings: false,
    oneSignalDirect: false
  };
  
  // Run all tests
  results.simpleNotification = await testSimpleNotification();
  results.bookingEndpoint = await testBookingEndpoint();
  results.adminBookings = await testAdminBookings();
  results.oneSignalDirect = await testOneSignalDirect();
  
  // Summary
  console.log('\n📊 Complete Notification Flow Results:');
  console.log('=====================================');
  
  const passed = Object.values(results).filter(r => r).length;
  const total = Object.keys(results).length;
  
  Object.entries(results).forEach(([test, passed]) => {
    const status = passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} ${test}`);
  });
  
  console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
  
  if (results.oneSignalDirect && results.simpleNotification) {
    console.log('\n🎉 Notification system is working!');
    console.log('\n📱 Expected Results:');
    console.log('   1. You should have received 2 notifications on your device');
    console.log('   2. One from OneSignal direct test');
    console.log('   3. One from the backend simple notification service');
    console.log('\n✅ If you received both notifications:');
    console.log('   - OneSignal integration is perfect');
    console.log('   - Backend notification service is working');
    console.log('   - Booking notifications will now work automatically');
  } else if (results.oneSignalDirect && !results.simpleNotification) {
    console.log('\n⚠️ OneSignal works but backend service needs deployment');
    console.log('   - The backend changes need to be deployed');
    console.log('   - Once deployed, all notifications will work');
  } else {
    console.log('\n❌ Notification system needs attention');
    console.log('   - Check OneSignal configuration');
    console.log('   - Verify device subscription');
  }
  
  console.log('\n🔧 Next Steps:');
  console.log('   1. Deploy backend changes to production');
  console.log('   2. Test booking creation in the Flutter app');
  console.log('   3. Verify admin receives notifications for new bookings');
  console.log('   4. Test status change notifications');
}

// Run the complete test
runCompleteNotificationTest().catch(console.error);