const express = require('express');
const router = express.Router();
const { Sequelize, Op } = require('sequelize');
const Student = require('../models/students');
const Gettedmarks = require('../models/gettedmarks');
const UniqueSubDegree = require('../models/uniqueSubDegree');

// Route to handle grades upload from Excel
router.post('/upload', async (req, res) => {
    try {
        const { gradesData } = req.body;
        
        if (!gradesData || !Array.isArray(gradesData) || gradesData.length === 0) {
            return res.status(400).json({ success: false, message: 'Invalid or empty data provided' });
        }

        let processed = 0;
        let errors = 0;
        const errorDetails = [];

        // Process each row in the Excel data
        for (const row of gradesData) {
            try {
                const { EnrollmentNumber, SubjectCode, Grade } = row;
                
                if (!EnrollmentNumber || !SubjectCode || !Grade) {
                    errorDetails.push({ row, error: 'Missing required fields' });
                    errors++;
                    continue;
                }

                // Find the student by enrollment number
                const student = await Student.findOne({
                    where: { enrollmentNumber: EnrollmentNumber }
                });

                if (!student) {
                    errorDetails.push({ row, error: `Student with enrollment number ${EnrollmentNumber} not found` });
                    errors++;
                    continue;
                }

                // Check if the subject exists
                const subject = await UniqueSubDegree.findOne({
                    where: { sub_code: SubjectCode }
                });

                if (!subject) {
                    errorDetails.push({ row, error: `Subject with code ${SubjectCode} not found` });
                    errors++;
                    continue;
                }

                // Find or create a record in Gettedmarks
                const [gettedmark, created] = await Gettedmarks.findOrCreate({
                    where: {
                        studentId: student.id,
                        subjectId: SubjectCode
                    },
                    defaults: {
                        studentId: student.id,
                        facultyId: 1, // Default faculty ID, adjust as needed
                        subjectId: SubjectCode,
                        grades: Grade
                    }
                });

                // If record exists, update the grades
                if (!created) {
                    await gettedmark.update({ grades: Grade });
                }

                processed++;
            } catch (rowError) {
                console.error('Error processing row:', rowError);
                errorDetails.push({ row, error: rowError.message });
                errors++;
            }
        }

        return res.status(200).json({
            success: true,
            message: `Processed ${processed} grade entries successfully with ${errors} errors.`,
            processed,
            errors,
            errorDetails: errors > 0 ? errorDetails : undefined
        });
    } catch (error) {
        console.error('Error uploading grades:', error);
        return res.status(500).json({
            success: false,
            message: 'An error occurred while processing grades data',
            error: error.message
        });
    }
});

module.exports = router;
