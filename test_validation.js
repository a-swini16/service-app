#!/usr/bin/env node
/**
 * Quick Validation Test Script
 * Tests common validation scenarios
 */

const http = require('http');

console.log('🧪 Testing Validation Scenarios...');

// Test valid user registration
function testValidUserRegistration() {
    return new Promise((resolve) => {
        const validUserData = JSON.stringify({
            name: 'Test User',
            email: 'testuser@example.com',
            password: 'testpass123',
            phone: '1234567890',
            address: '123 Test Street'
        });
        
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth/register',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(validUserData)
            },
            timeout: 5000
        };
        
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    if (res.statusCode === 201 || res.statusCode === 409) {
                        console.log('✅ Valid user registration works');
                    } else {
                        console.log('❌ Valid user registration failed:', response.message);
                    }
                } catch (error) {
                    console.log('❌ Invalid response from user registration');
                }
                resolve();
            });
        });
        
        req.on('error', () => {
            console.log('❌ Server not running - start with: cd service-app-backend && npm start');
            resolve();
        });
        
        req.on('timeout', () => {
            req.destroy();
            resolve();
        });
        
        req.write(validUserData);
        req.end();
    });
}

// Test invalid user registration
function testInvalidUserRegistration() {
    return new Promise((resolve) => {
        const invalidUserData = JSON.stringify({
            name: '',
            email: 'invalid-email',
            password: '123',
            phone: '123',
            address: ''
        });
        
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth/register',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(invalidUserData)
            },
            timeout: 5000
        };
        
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    if (res.statusCode === 400 && response.message === 'Validation failed') {
                        console.log('✅ Invalid user registration properly rejected');
                        console.log('   Errors found:', response.errors?.length || 0);
                    } else {
                        console.log('❌ Invalid user registration not properly validated');
                    }
                } catch (error) {
                    console.log('❌ Invalid response from user registration');
                }
                resolve();
            });
        });
        
        req.on('error', () => {
            console.log('❌ Server not running');
            resolve();
        });
        
        req.on('timeout', () => {
            req.destroy();
            resolve();
        });
        
        req.write(invalidUserData);
        req.end();
    });
}

async function runValidationTests() {
    console.log('\n🔍 Running validation tests...\n');
    await testValidUserRegistration();
    await testInvalidUserRegistration();
    console.log('\n✅ Validation tests completed!');
}

runValidationTests().catch(console.error);
