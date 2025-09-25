const Batch = require('./models/batch');
const Semester = require('./models/semester');
const ClassSection = require('./models/classSection');
require('./models/associations');

async function testCurrentSemester() {
    try {
        console.log('Testing currentSemester functionality...\n');

        // Get all batches
        const batches = await Batch.findAll();
        console.log(`Found ${batches.length} batches`);

        // Test with first batch
        if (batches.length > 0) {
            const testBatch = batches[0];
            console.log(`\nTesting with batch: ${testBatch.batchName}`);
            console.log(`Current semester before: ${testBatch.currentSemester || 'Not set'}`);

            // Get semesters for this batch
            const semesters = await Semester.findAll({
                where: { batchId: testBatch.id },
                order: [['semesterNumber', 'DESC']]
            });

            if (semesters.length > 0) {
                const latestSemester = semesters[0];
                console.log(`Latest semester: ${latestSemester.semesterNumber}`);

                // Update currentSemester to match the latest semester
                await testBatch.update({ currentSemester: latestSemester.semesterNumber });

                // Refresh the batch data
                await testBatch.reload();
                console.log(`Current semester after update: ${testBatch.currentSemester}`);
            } else {
                console.log('No semesters found for this batch');
            }
        }

        console.log('\n✅ Current semester test completed');

    } catch (error) {
        console.error('❌ Current semester test failed:', error);
    } finally {
        process.exit(0);
    }
}

testCurrentSemester(); 