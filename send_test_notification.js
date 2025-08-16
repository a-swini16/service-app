const https = require('https');

// OneSignal Configuration
const ONESIGNAL_APP_ID = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
const ONESIGNAL_REST_API_KEY = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';

console.log('🔔 Sending Test Notification...');
console.log('==============================');

/**
 * Send a test notification to all users
 */
function sendTestNotification() {
    const message = {
        app_id: ONESIGNAL_APP_ID,
        included_segments: ['All'],
        headings: { 
            en: '🧪 Terminal Test - ' + new Date().toLocaleTimeString()
        },
        contents: { 
            en: 'This is a test notification sent from your terminal! If you see this, notifications are working perfectly! 🎉'
        },
        data: {
            type: 'terminal_test',
            timestamp: new Date().toISOString(),
            test_id: Math.random().toString(36).substring(7)
        },
        // Notification settings
        android_sound: 'notification',
        ios_sound: 'default',
        android_visibility: 1,
        priority: 10,
        ttl: 3600
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

    console.log('📱 App ID:', ONESIGNAL_APP_ID);
    console.log('🔑 API Key:', ONESIGNAL_REST_API_KEY.substring(0, 20) + '...');
    console.log('📤 Sending notification...');
    console.log('');

    const req = https.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            try {
                const response = JSON.parse(data);
                
                if (response.id) {
                    console.log('🎉 SUCCESS! Test notification sent successfully!');
                    console.log('');
                    console.log('📧 Notification Details:');
                    console.log(`   ID: ${response.id}`);
                    console.log(`   Recipients: ${response.recipients || 'Unknown'}`);
                    console.log(`   External ID: ${response.external_id || 'None'}`);
                    console.log('');
                    console.log('📱 Check Your Device:');
                    console.log('   - Look for the notification in your device\'s notification tray');
                    console.log('   - Title should be: "🧪 Terminal Test - [current time]"');
                    console.log('   - Message should mention terminal test');
                    console.log('');
                    console.log('✅ If you received the notification, OneSignal is working perfectly!');
                } else {
                    console.log('❌ FAILED! OneSignal returned an error:');
                    console.log('');
                    console.log('📄 Full Response:');
                    console.log(JSON.stringify(response, null, 2));
                    
                    if (response.errors) {
                        console.log('');
                        console.log('🚨 Specific Errors:');
                        response.errors.forEach((error, index) => {
                            console.log(`   ${index + 1}. ${error}`);
                        });
                    }
                    
                    console.log('');
                    console.log('🔧 Troubleshooting:');
                    console.log('   - Verify your OneSignal App ID is correct');
                    console.log('   - Verify your REST API Key is correct');
                    console.log('   - Check if you have any users registered');
                    console.log('   - Visit OneSignal dashboard to check app status');
                }
            } catch (error) {
                console.log('❌ ERROR! Failed to parse OneSignal response:');
                console.log(`   Parse Error: ${error.message}`);
                console.log(`   Raw Response: ${data}`);
            }
        });
    });

    req.on('error', (error) => {
        console.log('❌ NETWORK ERROR! Failed to connect to OneSignal:');
        console.log(`   Error: ${error.message}`);
        console.log('');
        console.log('🔧 Troubleshooting:');
        console.log('   - Check your internet connection');
        console.log('   - Verify OneSignal API is accessible');
        console.log('   - Try again in a few moments');
    });

    req.write(postData);
    req.end();
}

// Send the test notification
sendTestNotification();