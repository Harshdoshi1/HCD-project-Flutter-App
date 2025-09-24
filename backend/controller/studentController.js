const express = require('express');
const { Op } = require('sequelize');
const Student = require('../models/students');
const Batch = require('../models/batch');
const jwt = require('jsonwebtoken');

// Create a new student
const createStudent = async (req, res) => {
    try {
        const { name, email, batchID, enrollment, currentSemester, currentClassName } = req.body;

        // Input validation
        if (!name || !email || !batchID || !enrollment || !currentSemester) {
            console.error("Missing required fields:", { name, email, batchID, enrollment, currentSemester });
            return res.status(400).json({
                error: "All fields are required",
                received: { name, email, batchID, enrollment, currentSemester }
            });
        }

        // Validate batch ID
        const batch = await Batch.findOne({
            where: { batchName: batchID },
            attributes: ['id', 'batchName']
        });

        if (!batch) {
            console.error("Batch not found:", batchID);
            return res.status(400).json({
                error: "Batch not found",
                receivedBatchName: batchID
            });
        }

        console.log("Found batch:", batch.toJSON());

        // Create student
        const student = await Student.create({
            name,
            email,
            batchId: batch.id,
            enrollmentNumber: enrollment,
            currnetsemester: currentSemester, // Note: using the field name as defined in the model
            currentClassName: currentClassName || null
        });

        console.log("Created student:", student.toJSON());
        res.status(201).json(student);
    } catch (error) {
        console.error("Error creating student:", error);
        res.status(500).json({
            error: error.message,
            type: error.name,
            details: error.errors?.map(e => e.message) || []
        });
    }
};

// Create multiple students with duplicate detection and detailed result
const createStudents = async (req, res) => {
    try {
        const students = req.body.students; // Expecting an array of student objects

        if (!Array.isArray(students) || students.length === 0) {
            return res.status(400).json({ error: "Invalid or empty students array" });
        }

        // Validate input rows and collect batch names
        const failures = [];
        const sanitized = [];
        const batchNames = new Set();
        const seenEnrollments = new Set();

        students.forEach((s, idx) => {
            const { name, email, batchID, enrollment, currentSemester, currentClassName } = s || {};
            if (!name || !email || !batchID || !enrollment || currentSemester === undefined) {
                failures.push({ row: idx + 1, enrollment, reason: 'Missing required fields' });
                return;
            }
            const sem = parseInt(currentSemester);
            if (isNaN(sem)) {
                failures.push({ row: idx + 1, enrollment, reason: 'Semester must be a number' });
                return;
            }
            // Check duplicates within the file itself
            if (seenEnrollments.has(enrollment)) {
                failures.push({ row: idx + 1, enrollment, reason: 'Duplicate enrollment in file' });
                return;
            }
            seenEnrollments.add(enrollment);
            batchNames.add(batchID);
            sanitized.push({ name, email, batchID, enrollment, currentSemester: sem, currentClassName });
        });

        if (sanitized.length === 0) {
            return res.status(400).json({ error: 'No valid rows to process', failed: failures, successCount: 0, failedCount: failures.length });
        }

        // Fetch batch IDs for provided batch names
        const batches = await Batch.findAll({
            where: { batchName: Array.from(batchNames) },
            attributes: ['id', 'batchName']
        });

        const batchMap = batches.reduce((acc, batch) => {
            acc[batch.batchName] = batch.id;
            return acc;
        }, {});

        // Check invalid batch names appearing in sanitized rows
        const invalidBatchRows = sanitized
            .filter(s => !batchMap[s.batchID])
            .map((s, i) => ({ row: i + 1, enrollment: s.enrollment, reason: `Invalid batch name: ${s.batchID}` }));
        if (invalidBatchRows.length) {
            // Remove invalid rows from sanitized
            const invalidSet = new Set(invalidBatchRows.map(r => r.enrollment));
            failures.push(...invalidBatchRows);
            for (let i = sanitized.length - 1; i >= 0; i--) {
                if (invalidSet.has(sanitized[i].enrollment)) sanitized.splice(i, 1);
            }
        }

        // Check for existing students by enrollmentNumber
        const enrollments = sanitized.map(s => s.enrollment);
        const existing = await Student.findAll({
            where: { enrollmentNumber: enrollments },
            attributes: ['enrollmentNumber']
        });
        const existingSet = new Set(existing.map(e => e.enrollmentNumber));

        const toCreate = [];
        sanitized.forEach((s, idx) => {
            if (existingSet.has(s.enrollment)) {
                failures.push({ row: idx + 1, enrollment: s.enrollment, reason: 'Enrollment already exists' });
            } else {
                toCreate.push({
                    name: s.name,
                    email: s.email,
                    batchId: batchMap[s.batchID],
                    enrollmentNumber: s.enrollment,
                    currnetsemester: s.currentSemester,
                    currentClassName: s.currentClassName || null
                });
            }
        });

        let createdStudents = [];
        if (toCreate.length > 0) {
            try {
                createdStudents = await Student.bulkCreate(toCreate, { validate: true });
            } catch (e) {
                // If any DB level errors occur, push a generic failure for all attempted rows
                console.error('Bulk create error:', e);
                toCreate.forEach(tc => failures.push({ enrollment: tc.enrollmentNumber, reason: 'Database error during insert' }));
            }
        }

        const successCount = createdStudents.length;
        const failedCount = failures.length;

        return res.status(200).json({
            message: 'Bulk upload processed',
            successCount,
            failedCount,
            failed: failures,
        });
    } catch (error) {
        console.error("Error creating students:", error);
        res.status(500).json({
            error: error.message,
            type: error.name,
            details: error.errors?.map(e => e.message) || []
        });
    }
};

// Get all students
const getAllStudents = async (req, res) => {
    try {
        const students = await Student.findAll({ include: Batch });
        res.status(200).json(students);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Get a single student by ID
const getStudentById = async (req, res) => {
    try {
        const student = await Student.findByPk(req.params.id, { include: Batch });
        if (!student) return res.status(404).json({ message: 'Student not found' });
        res.status(200).json(student);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Update student details
const updateStudent = async (req, res) => {
    try {
        const { name, email, batchId, enrollmentNumber, currentSemester } = req.body;
        const student = await Student.findByPk(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        await student.update({
            name,
            email,
            batchId,
            enrollmentNumber,
            currnetsemester: currentSemester
        });
        res.status(200).json(student);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Delete a student
const deleteStudent = async (req, res) => {
    try {
        const student = await Student.findByPk(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        await student.destroy();
        res.status(200).json({ message: 'Student deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Update multiple students' semesters
const updateStudentSemesters = async (req, res) => {
    try {
        const { studentIds, newSemester } = req.body;

        if (!studentIds || !Array.isArray(studentIds) || studentIds.length === 0) {
            return res.status(400).json({ message: 'No student IDs provided' });
        }

        if (newSemester === undefined || isNaN(parseInt(newSemester))) {
            return res.status(400).json({ message: 'Invalid semester value' });
        }

        // Update all selected students
        const updatePromises = studentIds.map(id =>
            Student.update(
                { currnetsemester: parseInt(newSemester) },
                { where: { id } }
            )
        );

        await Promise.all(updatePromises);

        res.status(200).json({ message: 'Student semesters updated successfully' });
    } catch (error) {
        console.error('Error updating student semesters:', error);
        res.status(500).json({ message: 'Failed to update student semesters', error: error.message });
    }
};

// Get students by batch ID
const getStudentsByBatch = async (req, res) => {
    try {
        const { batchId } = req.params;

        if (!batchId) {
            return res.status(400).json({ message: 'Batch ID is required' });
        }

        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) },
            attributes: ['id', 'name', 'enrollmentNumber', 'currnetsemester'],
            order: [['name', 'ASC']]
        });

        res.status(200).json(students);
    } catch (error) {
        console.error('Error fetching students by batch:', error);
        res.status(500).json({ message: 'Failed to fetch students', error: error.message });
    }
};

// Login student
const loginStudent = async (req, res) => {
    try {
        const { email, enrollmentNumber } = req.body;

        // Find student by email
        const student = await Student.findOne({
            where: { email },
            include: [{ model: Batch, attributes: ['batchName'] }]
        });

        if (!student) {
            console.log('Student not found for email:', email);
            return res.status(400).json({
                message: 'Invalid email or enrollment number',
                error: 'Student not found'
            });
        }

        // Verify enrollment number
        if (student.enrollmentNumber !== enrollmentNumber) {
            console.log('Invalid enrollment number for email:', email);
            return res.status(400).json({
                message: 'Invalid email or enrollment number',
                error: 'Invalid enrollment number'
            });
        }

        // Generate JWT token
        const jwt = require('jsonwebtoken');
        const token = jwt.sign(
            { id: student.id, email: student.email },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '1h' }
        );

        console.log('Login successful for email:', email);
        res.status(200).json({
            message: 'Login successful',
            token,
            user: {
                id: student.id,
                name: student.name,
                email: student.email,
                enrollmentNumber: student.enrollmentNumber,
                currentSemester: student.currnetsemester,

                batch: student.Batch ? student.Batch.batchName : null
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            message: 'Server Error',
            error: error.message
        });
    }
};

// Get current semester points for a student
const getCurrentSemesterPoints = async (req, res) => {
    try {
        const { enrollmentNumber, semester } = req.params;

        if (!enrollmentNumber || !semester) {
            return res.status(400).json({
                message: 'Enrollment number and semester are required'
            });
        }

        // Require the StudentPoints model
        const StudentPoints = require('../models/StudentPoints');

        // Find points for the specified student and semester
        const points = await StudentPoints.findAll({
            where: {
                enrollmentNumber,
                semester: parseInt(semester)
            },
            attributes: [
                'enrollmentNumber',
                'semester',
                'totalCocurricular',
                'totalExtracurricular'
            ]
        });

        // If no points records found
        if (!points || points.length === 0) {
            return res.status(200).json({
                enrollmentNumber,
                semester: parseInt(semester),
                totalCocurricular: 0,
                totalExtracurricular: 0
            });
        }

        // Calculate total points if multiple records exist
        let totalCocurricular = 0;
        let totalExtracurricular = 0;

        points.forEach(point => {
            totalCocurricular += point.totalCocurricular;
            totalExtracurricular += point.totalExtracurricular;
        });

        res.status(200).json({
            enrollmentNumber,
            semester: parseInt(semester),
            totalCocurricular,
            totalExtracurricular
        });

    } catch (error) {
        console.error('Error fetching current semester points:', error);
        res.status(500).json({
            message: 'Failed to fetch current semester points',
            error: error.message
        });
    }
};

// Get current semester points for all students
const getAllStudentsCurrentSemesterPoints = async (req, res) => {
    try {
        // Require the StudentPoints model and Student model
        const StudentPoints = require('../models/StudentPoints');
        const Student = require('../models/students');

        // Get all students to find their current semesters
        const students = await Student.findAll({
            attributes: ['id', 'name', 'enrollmentNumber', 'currnetsemester', 'email']
        });

        if (!students || students.length === 0) {
            return res.status(404).json({ message: 'No students found' });
        }

        // Create a map to store semester by enrollment number
        const studentSemesters = {};
        students.forEach(student => {
            studentSemesters[student.enrollmentNumber] = {
                id: student.id,
                name: student.name,
                email: student.email,
                semester: student.currnetsemester
            };
        });

        // Get enrollment numbers
        const enrollmentNumbers = students.map(s => s.enrollmentNumber);

        // Fetch points for all students
        const pointsRecords = await StudentPoints.findAll({
            where: {
                enrollmentNumber: enrollmentNumbers
            }
        });

        // Process points by student and semester
        const resultMap = {};

        // Initialize result with zero points for all students
        enrollmentNumbers.forEach(enrollment => {
            const student = studentSemesters[enrollment];
            resultMap[enrollment] = {
                studentId: student.id,
                name: student.name,
                email: student.email,
                enrollmentNumber: enrollment,
                semester: student.semester,
                totalCocurricular: 0,
                totalExtracurricular: 0
            };
        });

        // Add up points for current semester
        pointsRecords.forEach(point => {
            const enrollment = point.enrollmentNumber;
            const studentInfo = studentSemesters[enrollment];

            // Only add points for the student's current semester
            if (studentInfo && point.semester === studentInfo.semester) {
                resultMap[enrollment].totalCocurricular += point.totalCocurricular;
                resultMap[enrollment].totalExtracurricular += point.totalExtracurricular;
            }
        });

        // Convert map to array for response
        const results = Object.values(resultMap);

        res.status(200).json(results);
    } catch (error) {
        console.error('Error fetching all students current semester points:', error);
        res.status(500).json({
            message: 'Failed to fetch students points',
            error: error.message
        });
    }
};

module.exports = {
    deleteStudent,
    updateStudent,
    getStudentById,
    getAllStudents,
    createStudent,
    createStudents,
    updateStudentSemesters,
    getStudentsByBatch,
    loginStudent,
    getCurrentSemesterPoints,
    getAllStudentsCurrentSemesterPoints
};
