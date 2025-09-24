const { 
    Student, 
    StudentBloomsDistribution, 
    BloomsTaxonomy, 
    UniqueSubDegree, 
    StudentMarks
} = require('../models');
const { processStudentMarksDistribution } = require('../utils/marksDistributionHelper');

// Calculate and store Bloom's taxonomy distribution for a student using weighted marks
const calculateAndStoreBloomsDistribution = async (req, res) => {
    try {
        const { enrollmentNumber, semesterNumber } = req.params;
        console.log(`Calculating Bloom's distribution for enrollment: ${enrollmentNumber}, semester: ${semesterNumber}`);

        // Find the student
        const student = await Student.findOne({
            where: { enrollmentNumber: enrollmentNumber }
        });

        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }

        // Use the new weighted marks distribution logic
        const result = await processStudentMarksDistribution(
            student.id, 
            parseInt(semesterNumber)
        );

        res.status(200).json({
            message: 'Bloom\'s taxonomy distribution calculated and stored successfully',
            recordsCreated: result.recordsCreated,
            distributions: result.distributions
        });

    } catch (error) {
        console.error('Error calculating Bloom\'s distribution:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get stored Bloom's taxonomy distribution for a student using ORM
const getStoredBloomsDistribution = async (req, res) => {
    try {
        const { enrollmentNumber, semesterNumber } = req.params;
        console.log(`Fetching stored Bloom's distribution for enrollment: ${enrollmentNumber}, semester: ${semesterNumber}`);

        // Find the student using ORM
        const student = await Student.findOne({
            where: { enrollmentNumber: enrollmentNumber }
        });

        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }

        // Get stored distribution data using ORM
        const distributionData = await StudentBloomsDistribution.findAll({
            where: {
                studentId: student.id,
                semesterNumber: parseInt(semesterNumber)
            },
            include: [
                {
                    model: UniqueSubDegree,
                    as: 'subject',
                    attributes: ['sub_code', 'sub_name']
                },
                {
                    model: BloomsTaxonomy,
                    as: 'bloomsTaxonomy',
                    attributes: ['id', 'name']
                }
            ],
            order: [['subjectId', 'ASC'], ['bloomsTaxonomyId', 'ASC']]
        });

        console.log(`Found ${distributionData.length} stored distribution records`);

        // Process the data by subject
        const subjectBloomsData = {};
        distributionData.forEach(record => {
            const subjectCode = record.subjectId;
            const subjectName = record.subject?.sub_name || subjectCode;

            if (!subjectBloomsData[subjectCode]) {
                subjectBloomsData[subjectCode] = {
                    subject: subjectName,
                    code: subjectCode,
                    bloomsLevels: []
                };
            }

            subjectBloomsData[subjectCode].bloomsLevels.push({
                level: record.bloomsTaxonomy?.name || 'Unknown',
                marks: parseFloat(record.distributedMarks),
                totalMarks: parseFloat(record.totalPossibleMarks),
                percentage: parseFloat(record.percentage)
            });
        });

        // Convert to array format for frontend
        const bloomsDataArray = Object.values(subjectBloomsData);

        res.status(200).json({
            semester: parseInt(semesterNumber),
            bloomsDistribution: bloomsDataArray,
            totalRecords: distributionData.length
        });

    } catch (error) {
        console.error('Error fetching stored Bloom\'s distribution:', error);
        res.status(500).json({ error: error.message });
    }
};

// Direct function for internal use (without HTTP req/res) using weighted marks logic
const calculateAndStoreBloomsDistributionDirect = async (enrollmentNumber, semesterNumber, subjectId = null) => {
    try {
        console.log(`Calculating Bloom's distribution for enrollment: ${enrollmentNumber}, semester: ${semesterNumber}`);

        // Find the student using ORM
        const student = await Student.findOne({
            where: { enrollmentNumber: enrollmentNumber }
        });

        if (!student) {
            throw new Error('Student not found');
        }

        // Use the new weighted marks distribution logic
        const result = await processStudentMarksDistribution(
            student.id, 
            parseInt(semesterNumber),
            subjectId
        );

        console.log(`Stored ${result.recordsCreated} Bloom's distribution records`);
        return result.distributions;

    } catch (error) {
        console.error('Error calculating Bloom\'s distribution:', error);
        throw error;
    }
};

module.exports = {
    calculateAndStoreBloomsDistribution,
    getStoredBloomsDistribution,
    calculateAndStoreBloomsDistributionDirect
};
