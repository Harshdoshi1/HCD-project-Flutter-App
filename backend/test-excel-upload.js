const http = require('http');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'localhost';
const PORT = 5001;

// Test the Excel upload endpoints
async function testExcelUpload() {
    console.log('Testing Excel Upload functionality...\n');

    try {
        // Test 1: Get format instructions
        console.log('1. Testing GET /api/excel-upload/instructions');
        const instructionsResponse = await makeRequest('/api/excel-upload/instructions');
        console.log(`   Status: ${instructionsResponse.status}`);
        if (instructionsResponse.status === 200) {
            console.log('   ✅ Instructions endpoint working');
        } else {
            console.log('   ❌ Instructions endpoint failed');
        }

        console.log('');

        // Test 2: Test preview endpoint (without file)
        console.log('2. Testing POST /api/excel-upload/preview-all-classes (without file)');
        const previewResponse = await makeRequest('/api/excel-upload/preview-all-classes', 'POST');
        console.log(`   Status: ${previewResponse.status}`);
        if (previewResponse.status === 400) {
            console.log('   ✅ Preview endpoint properly rejecting missing file');
        } else {
            console.log('   ❌ Preview endpoint not handling missing file correctly');
        }

        console.log('');

        // Test 3: Test upload endpoint (without file)
        console.log('3. Testing POST /api/excel-upload/upload-all-classes (without file)');
        const uploadResponse = await makeRequest('/api/excel-upload/upload-all-classes', 'POST');
        console.log(`   Status: ${uploadResponse.status}`);
        if (uploadResponse.status === 400) {
            console.log('   ✅ Upload endpoint properly rejecting missing file');
        } else {
            console.log('   ❌ Upload endpoint not handling missing file correctly');
        }

    } catch (error) {
        console.error('Test failed:', error.message);
    }
}

function makeRequest(path, method = 'GET') {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: BASE_URL,
            port: PORT,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(data);
                    resolve({
                        status: res.statusCode,
                        data: jsonData
                    });
                } catch (error) {
                    resolve({
                        status: res.statusCode,
                        data: data
                    });
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.end();
    });
}

// Run the test
testExcelUpload();
