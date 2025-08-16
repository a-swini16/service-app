#!/usr/bin/env node

const https = require('https');

console.log('🔍 Comprehensive Service App Test Suite\n');
console.log('Testing all major functionality...\n');

// Test configuration
const BASE_URL = 'service-app-backend-6jpw.onrender.com';
const API_BASE = '/api';

// Helper function to make HTTPS requests
function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: BASE_URL,
      port: 443,
      path: `${API_BASE}${path}`,
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

// Test 1: Backend Health
async function testBackendHealth() {
  console.log('1️⃣ Testing Backend Health...');
  try {
    const response = await makeRequest('/health');
    
    if (response.statusCode === 200 && response.data.success) {
      console.log(`✅ Backend is healthy`);
      console.log(`   Uptime: ${response.data.uptime} minutes`);
      console.log(`   Memory: ${response.data.memory?.used || 'N/A'}`);
      return true;
    } else {
      console.log(`❌ Backend health check failed: ${response.statusCode}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Backend health check error: ${error.message}`);
    return false;
  }
}

// Test 2: Admin Bookings API
async function testAdminBookings() {
  console.log('\n2️⃣ Testing Admin Bookings API...');
  try {
    const response = await makeRequest('/admin/bookings');
    
    if (response.statusCode === 200 && response.data.success) {
      const bookings = response.data.bookings || [];
      console.log(`✅ Admin bookings API working`);
      console.log(`   Total bookings: ${bookings.length}`);
      console.log(`   Total pages: ${response.data.totalPages || 1}`);
      
      if (bookings.length > 0) {
        const statusCounts = {};
        bookings.forEach(booking => {
          statusCounts[booking.status] = (statusCounts[booking.status] || 0) + 1;
        });
        
        console.log(`   Status breakdown:`);
        Object.entries(statusCounts).forEach(([status, count]) => {
          console.log(`     - ${status}: ${count}`);
        });
        
        // Show sample booking
        const sample = bookings[0];
        console.log(`   Sample booking:`);
        console.log(`     - ID: ${sample._id}`);
        console.log(`     - Customer: ${sample.customerName}`);
        console.log(`     - Service: ${sample.serviceType}`);
        console.log(`     - Status: ${sample.status}`);
      }
      
      return true;
    } else {
      console.log(`❌ Admin bookings API failed: ${response.statusCode}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Admin bookings API error: ${error.message}`);
    return false;
  }
}

// Test 3: User Bookings API
async function testUserBookings() {
  console.log('\n3️⃣ Testing User Bookings API...');
  
  // Test with known phone numbers from the data
  const testPhones = ['6371448994', '9178160538'];
  let totalFound = 0;
  
  for (const phone of testPhones) {
    try {
      const response = await makeRequest(`/bookings/user/${phone}`);
      
      if (response.statusCode === 200 && response.data.success) {
        const bookings = response.data.bookings || [];
        console.log(`✅ User bookings for ${phone}: ${bookings.length} found`);
        totalFound += bookings.length;
        
        if (bookings.length > 0) {
          bookings.forEach((booking, index) => {
            console.log(`     ${index + 1}. ${booking.serviceType} - ${booking.status}`);
          });
        }
      } else if (response.statusCode === 404) {
        console.log(`📭 No bookings found for ${phone}`);
      } else {
        console.log(`❌ User bookings API failed for ${phone}: ${response.statusCode}`);
      }
    } catch (error) {
      console.log(`❌ User bookings API error for ${phone}: ${error.message}`);
    }
  }
  
  console.log(`   Total user bookings found: ${totalFound}`);
  return totalFound > 0;
}

// Test 4: Notification System
async function testNotificationSystem() {
  console.log('\n4️⃣ Testing Notification System...');
  try {
    // Test OneSignal notification
    const testNotification = {
      title: '🧪 System Test Notification',
      message: 'This is a test notification from the comprehensive test suite',
      type: 'system_test'
    };
    
    const response = await makeRequest('/notifications/test', 'POST', testNotification);
    
    if (response.statusCode === 200 || response.statusCode === 201) {
      console.log(`✅ Notification system working`);
      console.log(`   Response: ${JSON.stringify(response.data)}`);
      return true;
    } else {
      console.log(`❌ Notification system failed: ${response.statusCode}`);
      console.log(`   Response: ${JSON.stringify(response.data)}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Notification system error: ${error.message}`);
    return false;
  }
}

// Test 5: WebSocket Connection
async function testWebSocketConnection() {
  console.log('\n5️⃣ Testing WebSocket Connection...');
  try {
    // Test WebSocket health endpoint
    const response = await makeRequest('/websocket/health');
    
    if (response.statusCode === 200) {
      console.log(`✅ WebSocket service is available`);
      return true;
    } else {
      console.log(`⚠️ WebSocket health endpoint returned: ${response.statusCode}`);
      return false;
    }
  } catch (error) {
    console.log(`⚠️ WebSocket test inconclusive: ${error.message}`);
    return false;
  }
}

// Main test runner
async function runComprehensiveTest() {
  console.log('🚀 Starting comprehensive test suite...\n');
  
  const results = {
    backendHealth: false,
    adminBookings: false,
    userBookings: false,
    notifications: false,
    websocket: false
  };
  
  // Run all tests
  results.backendHealth = await testBackendHealth();
  results.adminBookings = await testAdminBookings();
  results.userBookings = await testUserBookings();
  results.notifications = await testNotificationSystem();
  results.websocket = await testWebSocketConnection();
  
  // Summary
  console.log('\n📊 Test Results Summary:');
  console.log('========================');
  
  const passed = Object.values(results).filter(r => r).length;
  const total = Object.keys(results).length;
  
  Object.entries(results).forEach(([test, passed]) => {
    const status = passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} ${test}`);
  });
  
  console.log(`\n🎯 Overall: ${passed}/${total} tests passed`);
  
  if (passed === total) {
    console.log('\n🎉 All systems are working correctly!');
    console.log('\n💡 Flutter App Issues (if any) are likely in:');
    console.log('   1. Data parsing in BookingModel.fromJson()');
    console.log('   2. UI state management in providers');
    console.log('   3. Authentication token handling');
    console.log('   4. OneSignal Flutter SDK configuration');
  } else {
    console.log('\n⚠️ Some backend systems need attention.');
    console.log('   Fix backend issues before testing Flutter app.');
  }
  
  console.log('\n🔧 Next Steps:');
  console.log('   1. Install the new APK: build\\app\\outputs\\flutter-apk\\app-release.apk');
  console.log('   2. Test the "API Debug Test" option in the app menu');
  console.log('   3. Check admin panel and user booking tracking');
  console.log('   4. Verify notifications are received on device');
}

// Run the test suite
runComprehensiveTest().catch(console.error);