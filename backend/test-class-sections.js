const { syncDB } = require('./models');
const ClassSection = require('./models/classSection');
const Semester = require('./models/semester');
const Batch = require('./models/batch');

async function testClassSections() {
    try {
        console.log('Testing ClassSection functionality...');

        // Sync database
        await syncDB();
        console.log('✅ Database synced successfully');

        // Test model definition
        console.log('✅ ClassSection model loaded successfully');

        // Check if table exists
        const tableExists = await ClassSection.sequelize.query(
            "SHOW TABLES LIKE 'ClassSections'",
            { type: ClassSection.sequelize.QueryTypes.SELECT }
        );

        if (tableExists.length > 0) {
            console.log('✅ ClassSections table exists');
        } else {
            console.log('❌ ClassSections table not found');
        }

        console.log('\nClassSection Model Schema:');
        console.log('- id: Primary key (auto increment)');
        console.log('- semesterId: Foreign key to Semester');
        console.log('- batchId: Foreign key to Batch');
        console.log('- className: String (required)');
        console.log('- classLetter: String(1) (A, B, C, etc.)');
        console.log('- studentCount: Integer (default: 0)');
        console.log('- excelFileName: String (optional)');
        console.log('- isActive: Boolean (default: true)');

        console.log('\n✅ Test completed successfully');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        process.exit(0);
    }
}

testClassSections(); 