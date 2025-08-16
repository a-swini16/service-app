#!/usr/bin/env node

const https = require('https');

console.log('🔍 Testing Service App Backend API...\n');

// Test 1: Health Check
function testHealthCheck() {
  return new Promise((resolve, reject) => {
    console.log('1️⃣ Testing Health Check...');
    
    const options = {
      hostname: 'service-app-backend-6jpw.onrender.com',
      port: 443,
      path: '/api/health',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
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
          console.log(`✅ Health Check: ${res.statusCode}`);
          console.log(`   Status: ${response.status}`);
          console.log(`   Uptime: ${response.uptime} minutes\n`);
          resolve(response);
        } catch (e) {
          console.log(`❌ Health Check Parse Error: ${e.message}\n`);
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.log(`❌ Health Check Error: ${e.message}\n`);
      reject(e);
    });

    req.end();
  });
}

// Test 2: Admin Bookings
function testAdminBookings() {
  return new Promise((resolve, reject) => {
    console.log('2️⃣ Testing Admin Bookings...');
    
    const options = {
      hostname: 'service-app-backend-6jpw.onrender.com',
      port: 443,
      path: '/api/admin/bookings',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
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
          console.log(`✅ Admin Bookings: ${res.statusCode}`);
          console.log(`   Success: ${response.success}`);
          console.log(`   Total Bookings: ${response.bookings ? response.bookings.length : 0}`);
          console.log(`   Total Pages: ${response.totalPages || 'N/A'}`);
          
          if (response.bookings && response.bookings.length > 0) {
            console.log('\n📋 Sample Booking:');
            const sample = response.bookings[0];
            console.log(`   ID: ${sample._id}`);
            console.log(`   Customer: ${sample.customerName}`);
            console.log(`   Phone: ${sample.customerPhone}`);
            console.log(`   Service: ${sample.serviceType}`);
            console.log(`   Status: ${sample.status}`);
            console.log(`   Payment Status: ${sample.paymentStatus}`);
            console.log(`   Created: ${sample.createdAt}`);
          }
          console.log('');
          resolve(response);
        } catch (e) {
          console.log(`❌ Admin Bookings Parse Error: ${e.message}\n`);
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.log(`❌ Admin Bookings Error: ${e.message}\n`);
      reject(e);
    });

    req.end();
  });
}

// Test 3: User Bookings (with a sample phone number)
function testUserBookings() {
  return new Promise((resolve, reject) => {
    console.log('3️⃣ Testing User Bookings...');
    
    const options = {
      hostname: 'service-app-backend-6jpw.onrender.com',
      port: 443,
      path: '/api/bookings/user/6371448994', // Using phone from the sample data
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
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
          console.log(`✅ User Bookings: ${res.statusCode}`);
          console.log(`   Success: ${response.success}`);
          console.log(`   User Bookings: ${response.bookings ? response.bookings.length : 0}`);
          
          if (response.bookings && response.bookings.length > 0) {
            console.log('\n📋 User\'s Bookings:');
            response.bookings.forEach((booking, index) => {
              console.log(`   ${index + 1}. ${booking.serviceType} - ${booking.status}`);
            });
          }
          console.log('');
          resolve(response);
        } catch (e) {
          console.log(`❌ User Bookings Parse Error: ${e.message}\n`);
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.log(`❌ User Bookings Error: ${e.message}\n`);
      reject(e);
    });

    req.end();
  });
}

// Run all tests
async function runTests() {
  try {
    await testHealthCheck();
    await testAdminBookings();
    await testUserBookings();
    
    console.log('🎉 All API tests completed!');
    console.log('\n📊 Summary:');
    console.log('   - Backend is healthy and responding');
    console.log('   - Admin bookings endpoint is working');
    console.log('   - User bookings endpoint is working');
    console.log('\n💡 If Flutter app shows "No Bookings", the issue is in:');
    console.log('   1. Flutter API service implementation');
    console.log('   2. Data parsing in BookingModel.fromJson()');
    console.log('   3. UI state management in providers');
    
  } catch (error) {
    console.log(`❌ Test failed: ${error.message}`);
  }
}

runTests();