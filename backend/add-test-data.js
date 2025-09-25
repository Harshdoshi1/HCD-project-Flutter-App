const ClassSection = require('./models/classSection');
const Semester = require('./models/semester');
const Batch = require('./models/batch');
require('./models/associations');

async function addTestData() {
    try {
        console.log('Adding test student data to class sections...\n');

        // Get all class sections
        const classSections = await ClassSection.findAll({
            where: { isActive: true },
            include: [{
                model: Semester,
                as: 'semester'
            }]
        });

        console.log(`Found ${classSections.length} active class sections`);

        if (classSections.length === 0) {
            console.log('No class sections found. Please add some semesters with class sections first.');
            return;
        }

        // Add random student counts to each class section
        for (const classSection of classSections) {
            const randomStudentCount = Math.floor(Math.random() * 20) + 30; // 30-50 students
            await classSection.update({ studentCount: randomStudentCount });
            console.log(`Updated ${classSection.className} (${classSection.classLetter}) with ${randomStudentCount} students`);
        }

        console.log('\n✅ Test data added successfully');

        // Show summary
        const totalStudents = classSections.reduce((sum, cs) => sum + cs.studentCount, 0);
        console.log(`Total students across all classes: ${totalStudents}`);

    } catch (error) {
        console.error('❌ Failed to add test data:', error);
    } finally {
        process.exit(0);
    }
}

addTestData(); 