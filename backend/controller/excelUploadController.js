const xlsx = require('xlsx');
const Student = require('../models/students');
const ClassSection = require('../models/classSection');
const { sequelize } = require('../models');
const { validateExcelHeaders, validateStudentData, sanitizeStudentData } = require('../utils/excelValidator');

// Parse Excel file and extract student data
const parseExcelFile = (buffer) => {
    try {
        console.log('Starting Excel file parsing...');
        console.log('Buffer size:', buffer.length);

        const workbook = xlsx.read(buffer, { type: 'buffer' });
        console.log('Workbook created, sheet names:', workbook.SheetNames);

        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        console.log('Worksheet loaded:', sheetName);

        // Convert to JSON with specific column mapping
        const data = xlsx.utils.sheet_to_json(worksheet, { header: 1 });
        console.log('Data converted to JSON, rows:', data.length);
        console.log('First few rows:', data.slice(0, 3));

        if (data.length < 2) {
            throw new Error('Excel file must have at least a header row and one data row');
        }

        // Extract headers from first row
        const headers = data[0];
        console.log('Excel headers:', headers);

        // Validate headers
        const headerValidation = validateExcelHeaders(headers);
        console.log('Header validation result:', headerValidation);

        if (!headerValidation.isValid) {
            throw new Error(`Missing required columns: ${headerValidation.missingColumns.join(', ')}`);
        }

        const { columnIndices } = headerValidation;
        console.log('Column indices:', columnIndices);

        // Process data rows (skip header row)
        const students = [];
        const validationErrors = [];

        for (let i = 1; i < data.length; i++) {
            const row = data[i];
            if (row.length === 0) continue; // Skip empty rows

            const student = {
                enrollmentNumber: row[columnIndices.enrollment]?.toString().trim() || '',
                name: row[columnIndices.name]?.toString().trim() || '',
                email: row[columnIndices.email]?.toString().trim() || '',
                batchName: row[columnIndices.batchName]?.toString().trim() || '',
                semesterNumber: row[columnIndices.semesterNumber] ? parseInt(row[columnIndices.semesterNumber]) : null,
                className: row[columnIndices.class]?.toString().trim() || ''
            };

            // Validate student data
            const studentValidation = validateStudentData(student, i);
            if (!studentValidation.isValid) {
                validationErrors.push(...studentValidation.errors);
            }

            if (student.enrollmentNumber) {
                students.push(sanitizeStudentData(student));
            }
        }

        // If there are validation errors, throw them
        if (validationErrors.length > 0) {
            throw new Error(`Data validation errors:\n${validationErrors.join('\n')}`);
        }

        console.log(`Parsed ${students.length} students from Excel`);
        return students;

    } catch (error) {
        console.error('Error parsing Excel file:', error);
        throw new Error(`Failed to parse Excel file: ${error.message}`);
    }
};

// Update student class names based on Excel data
const updateStudentClassNames = async (students, className) => {
    const transaction = await sequelize.transaction();

    try {
        let updatedCount = 0;
        let errors = [];

        for (const studentData of students) {
            try {
                // Find student by enrollment number
                const student = await Student.findOne({
                    where: { enrollmentNumber: studentData.enrollmentNumber },
                    transaction
                });

                if (student) {
                    // Update current class name
                    await student.update({
                        currentClassName: className
                    }, { transaction });

                    updatedCount++;
                    console.log(`Updated class name for student: ${studentData.enrollmentNumber}`);
                } else {
                    errors.push(`Student not found with enrollment: ${studentData.enrollmentNumber}`);
                }
            } catch (error) {
                errors.push(`Error updating student ${studentData.enrollmentNumber}: ${error.message}`);
            }
        }

        await transaction.commit();

        return {
            success: true,
            updatedCount,
            errors,
            message: `Successfully updated ${updatedCount} students with class name: ${className}`
        };

    } catch (error) {
        await transaction.rollback();
        throw error;
    }
};

// Main function to process Excel upload
exports.processExcelUpload = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No Excel file uploaded'
            });
        }

        const { className, semesterId, batchId } = req.body;

        if (!className || !semesterId || !batchId) {
            return res.status(400).json({
                success: false,
                message: 'Missing required parameters: className, semesterId, batchId'
            });
        }

        console.log('Processing Excel upload for:', { className, semesterId, batchId });

        // Parse Excel file
        const students = parseExcelFile(req.file.buffer);

        if (students.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No valid student data found in Excel file'
            });
        }

        // Update student class names
        const result = await updateStudentClassNames(students, className);

        // Update class section with Excel file info
        await ClassSection.update({
            excelFileName: req.file.originalname,
            studentCount: students.length
        }, {
            where: {
                className: className,
                semesterId: parseInt(semesterId),
                batchId: parseInt(batchId)
            }
        });

        res.status(200).json({
            success: true,
            message: result.message,
            data: {
                totalStudents: students.length,
                updatedCount: result.updatedCount,
                errors: result.errors,
                className,
                semesterId,
                batchId
            }
        });

    } catch (error) {
        console.error('Error processing Excel upload:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing Excel upload',
            error: error.message
        });
    }
};

// Get Excel upload history for a class
exports.getExcelUploadHistory = async (req, res) => {
    try {
        const { className, semesterId, batchId } = req.params;

        const classSection = await ClassSection.findOne({
            where: {
                className: className,
                semesterId: parseInt(semesterId),
                batchId: parseInt(batchId)
            }
        });

        if (!classSection) {
            return res.status(404).json({
                success: false,
                message: 'Class section not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                className: classSection.className,
                excelFileName: classSection.excelFileName,
                studentCount: classSection.studentCount,
                lastUpdated: classSection.updatedAt
            }
        });

    } catch (error) {
        console.error('Error getting Excel upload history:', error);
        res.status(500).json({
            success: false,
            message: 'Error getting Excel upload history',
            error: error.message
        });
    }
};

// Preview Excel data without updating database
exports.previewExcelData = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No Excel file uploaded'
            });
        }

        // Parse Excel file
        const students = parseExcelFile(req.file.buffer);

        res.status(200).json({
            success: true,
            data: {
                totalStudents: students.length,
                preview: students.slice(0, 10), // Show first 10 students
                headers: ['enrollmentNumber', 'name', 'email', 'batchName', 'semesterNumber', 'className']
            }
        });

    } catch (error) {
        console.error('Error previewing Excel data:', error);
        res.status(500).json({
            success: false,
            message: 'Error previewing Excel data',
            error: error.message
        });
    }
};

// Preview Excel data for all classes
exports.previewExcelDataAllClasses = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No Excel file uploaded'
            });
        }

        // Parse Excel file
        const students = parseExcelFile(req.file.buffer);

        // Group students by class
        const classDistribution = {};
        students.forEach(student => {
            const className = student.className;
            if (className) {
                classDistribution[className] = (classDistribution[className] || 0) + 1;
            }
        });

        res.status(200).json({
            success: true,
            data: {
                totalStudents: students.length,
                classDistribution,
                preview: students.slice(0, 10), // Show first 10 students
                headers: ['enrollmentNumber', 'name', 'email', 'batchName', 'semesterNumber', 'className']
            }
        });

    } catch (error) {
        console.error('Error previewing Excel data for all classes:', error);
        res.status(500).json({
            success: false,
            message: 'Error previewing Excel data for all classes',
            error: error.message
        });
    }
};

// Process Excel upload for all classes
exports.processExcelUploadAllClasses = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No Excel file uploaded'
            });
        }

        const { semesterId, batchId, numberOfClasses } = req.body;

        if (!semesterId || !batchId || !numberOfClasses) {
            return res.status(400).json({
                success: false,
                message: 'Missing required parameters: semesterId, batchId, numberOfClasses'
            });
        }

        console.log('Processing Excel upload for all classes:', { semesterId, batchId, numberOfClasses });

        // Parse Excel file
        const students = parseExcelFile(req.file.buffer);

        if (students.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No valid student data found in Excel file'
            });
        }

        // Group students by class
        const studentsByClass = {};
        students.forEach(student => {
            const className = student.className;
            if (className) {
                if (!studentsByClass[className]) {
                    studentsByClass[className] = [];
                }
                studentsByClass[className].push(student);
            }
        });

        // Update student class names for all classes
        const transaction = await sequelize.transaction();
        let totalUpdated = 0;
        let errors = [];

        try {
            for (const [className, classStudents] of Object.entries(studentsByClass)) {
                console.log(`Processing class: ${className} with ${classStudents.length} students`);

                // Update student class names
                const result = await updateStudentClassNames(classStudents, className);
                totalUpdated += result.updatedCount;
                errors.push(...result.errors);

                // Update class section with Excel file info
                await ClassSection.update({
                    excelFileName: req.file.originalname,
                    studentCount: classStudents.length
                }, {
                    where: {
                        className: className,
                        semesterId: parseInt(semesterId),
                        batchId: parseInt(batchId)
                    },
                    transaction
                });
            }

            await transaction.commit();

            res.status(200).json({
                success: true,
                message: `Successfully processed Excel upload for all classes`,
                data: {
                    totalStudents: students.length,
                    totalUpdated,
                    classDistribution: Object.fromEntries(
                        Object.entries(studentsByClass).map(([className, students]) => [className, students.length])
                    ),
                    errors: errors.filter(error => error), // Remove empty errors
                    semesterId,
                    batchId
                }
            });

        } catch (error) {
            await transaction.rollback();
            throw error;
        }

    } catch (error) {
        console.error('Error processing Excel upload for all classes:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing Excel upload for all classes',
            error: error.message
        });
    }
};
