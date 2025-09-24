const fetch = require('node-fetch');

async function testAPI() {
    try {
        console.log('Testing API endpoints...\n');

        // Test 1: Get all batches
        console.log('1. Testing get all batches...');
        const batchesResponse = await fetch('http://localhost:5001/api/batches/getAllBatches');
        const batches = await batchesResponse.json();
        console.log(`✅ Found ${batches.length} batches`);

        if (batches.length > 0) {
            const testBatch = batches[0];
            console.log(`   Using batch: ${testBatch.batchName}`);

            // Test 2: Get semester-wise batch info
            console.log('\n2. Testing get semester-wise batch info...');
            const batchInfoResponse = await fetch(`http://localhost:5001/api/class-sections/getSemesterWiseBatchInfo/${encodeURIComponent(testBatch.batchName)}`);

            if (batchInfoResponse.ok) {
                const batchInfo = await batchInfoResponse.json();
                console.log('✅ Batch info retrieved successfully');
                console.log(`   Batch: ${batchInfo.batchName}`);
                console.log(`   Course Type: ${batchInfo.courseType}`);
                console.log(`   Total Semesters: ${batchInfo.totalSemesters}`);
                console.log(`   Semesters with data: ${batchInfo.semesters.length}`);

                if (batchInfo.semesters.length > 0) {
                    const firstSemester = batchInfo.semesters[0];
                    console.log(`   First semester: ${firstSemester.semesterNumber}`);
                    console.log(`   Classes in first semester: ${firstSemester.totalClasses}`);
                    console.log(`   Students in first semester: ${firstSemester.totalStudents}`);
                }
            } else {
                console.log('❌ Failed to get batch info');
                const error = await batchInfoResponse.text();
                console.log(`   Error: ${error}`);
            }
        } else {
            console.log('⚠️ No batches found to test with');
        }

        console.log('\n✅ API test completed');

    } catch (error) {
        console.error('❌ API test failed:', error.message);
    }
}

// Check if server is running
async function checkServer() {
    try {
        const response = await fetch('http://localhost:5001/api/batches/getAllBatches');
        if (response.ok) {
            console.log('✅ Server is running');
            await testAPI();
        } else {
            console.log('❌ Server responded with error');
        }
    } catch (error) {
        console.log('❌ Server is not running. Please start the server first:');
        console.log('   cd backend && npm start');
    }
}

checkServer(); 