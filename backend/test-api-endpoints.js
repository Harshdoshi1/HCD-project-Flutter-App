const http = require('http');

const BASE_URL = 'localhost';
const PORT = 5001;

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

async function testEndpoints() {
    console.log('Testing API endpoints...\n');

    try {
        // Test 1: Event Outcomes - Technical
        console.log('1. Testing GET /api/event-outcomes/type/Technical');
        const techResponse = await makeRequest('/api/event-outcomes/type/Technical');
        console.log(`   Status: ${techResponse.status}`);
        console.log(`   Data: ${JSON.stringify(techResponse.data, null, 2)}`);

        console.log('');

        // Test 2: Event Outcomes - Non-Technical
        console.log('2. Testing GET /api/event-outcomes/type/Non-Technical');
        const nonTechResponse = await makeRequest('/api/event-outcomes/type/Non-Technical');
        console.log(`   Status: ${nonTechResponse.status}`);
        console.log(`   Data: ${JSON.stringify(nonTechResponse.data, null, 2)}`);

        console.log('');

        // Test 3: All Events
        console.log('3. Testing GET /api/events/all');
        const eventsResponse = await makeRequest('/api/events/all');
        console.log(`   Status: ${eventsResponse.status}`);
        console.log(`   Data: ${JSON.stringify(eventsResponse.data, null, 2)}`);

    } catch (error) {
        console.error('Test failed:', error.message);
    }
}

// Run the test
testEndpoints();
