const express = require('express');
const router = express.Router();
const { Sequelize, Op } = require('sequelize');
const Student = require('../models/students');
const Gettedmarks = require('../models/gettedmarks');
const UniqueSubDegree = require('../models/uniqueSubDegree');
const Subject = require('../models/subjects');
const Semester = require('../models/semester');
const Batch = require('../models/batch');
const ComponentMarks = require('../models/componentMarks');
const StudentCPI = require('../models/studentCPI');

// Route to get academic details for a student in a specific semester
router.get('/student/:enrollmentNumber/semester/:semesterId', async (req, res) => {
    console.log('Fetching academic details for student:', req.params.enrollmentNumber, 'semester:', req.params.semesterId);
    try {
        const { enrollmentNumber, semesterId } = req.params;
        
        // Find the student by enrollment number
        const student = await Student.findOne({
            where: { enrollmentNumber },
            include: [{ model: Batch }]
        });

        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }

        // Get the batch ID from the student
        const batchId = student.batchId;

        // Find all subjects for this batch and semester
        const subjects = await Subject.findAll({
            where: { 
                batchId,
                semesterId
            },
            include: [{ model: Semester }]
        });

        if (!subjects || subjects.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'No subjects found for this batch and semester' 
            });
        }

        // Get all subject codes from UniqueSubDegree that match the subject names
        const subjectNames = subjects.map(subject => subject.subjectName);
        console.log('Subject names to find:', subjectNames);
        
        const uniqueSubjects = await UniqueSubDegree.findAll({
            where: {
                sub_name: {
                    [Op.in]: subjectNames
                }
            }
        });
        
        console.log('Found unique subjects:', uniqueSubjects.map(s => ({ code: s.sub_code, name: s.sub_name })));

        // Create a map of subject name to subject code
        const subjectCodeMap = {};
        uniqueSubjects.forEach(subject => {
            subjectCodeMap[subject.sub_name] = subject.sub_code;
        });

        // Get component marks for all subjects
        const componentMarksPromises = uniqueSubjects.map(async (subject) => {
            return await ComponentMarks.findOne({
                where: { subjectId: subject.sub_code }
            });
        });

        const componentMarks = await Promise.all(componentMarksPromises);

        // Create a map of subject code to component marks
        const componentMarksMap = {};
        componentMarks.forEach((marks, index) => {
            if (marks) {
                componentMarksMap[uniqueSubjects[index].sub_code] = marks;
            }
        });

        // Get student's marks directly from Gettedmarks without including the UniqueSubDegree model
        // This simplifies the query and ensures we get all marks regardless of subject code
        const studentMarks = await Gettedmarks.findAll({
            where: { studentId: student.id },
            attributes: ['id', 'studentId', 'subjectId', 'ese', 'cse', 'ia', 'tw', 'viva', 'grades']
        });
        
        console.log(`Found ${studentMarks.length} marks entries for student ID ${student.id}`);
        
        // Log the student marks with grades for debugging
        console.log('Student marks from database:', studentMarks.map(mark => ({
            id: mark.id,
            studentId: mark.studentId,
            subjectId: mark.subjectId,
            grades: mark.grades
        })));

        // Get student's CPI/SPI information
        const studentCPI = await StudentCPI.findOne({
            where: {
                EnrollmentNumber: enrollmentNumber,
                SemesterId: semesterId
            }
        });

        // Prepare the response data
        const academicDetails = {
            student: {
                id: student.id,
                name: student.name,
                enrollmentNumber: student.enrollmentNumber,
                batch: student.Batch ? student.Batch.batchName : 'Unknown',
                semester: semesterId
            },
            semesterInfo: {
                cpi: studentCPI ? studentCPI.CPI : null,
                spi: studentCPI ? studentCPI.SPI : null
            },
            subjects: subjects.map(subject => {
                const subjectCode = subjectCodeMap[subject.subjectName] || null;
                const componentMark = componentMarksMap[subjectCode] || {};
                // Find the student mark for this subject by comparing subjectId
                const studentMark = studentMarks.find(mark => {
                    // Log to debug the comparison
                    console.log(`Comparing mark.subjectId: '${mark.subjectId}' with subject code: '${subjectCode}'`);
                    return mark.subjectId === subjectCode;
                }) || {};
                
                // If no mark found, try to find by subject name as a fallback
                if (!studentMark.id && subjectCode) {
                    console.log(`No mark found by subject code, trying to find by subject name: ${subject.subjectName}`);
                    const markByName = studentMarks.find(mark => {
                        // Some systems might store subject name instead of code
                        return mark.subjectId === subject.subjectName;
                    });
                    if (markByName) {
                        console.log(`Found mark by subject name instead: ${subject.subjectName}`);
                        return markByName;
                    }
                }
                
                console.log(`Looking for marks for subject ${subjectCode}:`, studentMark ? {
                    found: !!studentMark,
                    subjectId: studentMark.subjectId,
                    grades: studentMark.grades
                } : 'Not found');
                
                // Get the grade from studentMark if it exists
                const grade = studentMark.grades || 'N/A';
                console.log(`Grade for subject ${subject.subjectName} (${subjectCode}):`, grade);
                
                return {
                    id: subject.id,
                    name: subject.subjectName,
                    code: subjectCode,
                    componentMarks: {
                        ese: componentMark.ese_marks || 0,
                        cse: componentMark.cse_marks || 0,
                        ia: componentMark.ia_marks || 0,
                        tw: componentMark.tw_marks || 0,
                        viva: componentMark.viva_marks || 0
                    },
                    studentMarks: {
                        ese: studentMark.ese || 0,
                        cse: studentMark.cse || 0,
                        ia: studentMark.ia || 0,
                        tw: studentMark.tw || 0,
                        viva: studentMark.viva || 0,
                        grades: grade
                    }
                };
            })
        };

        return res.status(200).json({
            success: true,
            data: academicDetails
        });
    } catch (error) {
        console.error('Error fetching academic details:', error);
        return res.status(500).json({
            success: false,
            message: 'An error occurred while fetching academic details',
            error: error.message
        });
    }
});

module.exports = router;
