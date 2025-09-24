const StudentCPI = require('../models/studentCPI');
const Batch = require('../models/batch');
const Semester = require('../models/semester');
const Student = require('../models/students');
const Subject = require('../models/subjects');
const UniqueSubDegree = require('../models/uniqueSubDegree');
const ComponentMarks = require('../models/componentMarks');
const ComponentWeightage = require('../models/componentWeightage');
const Gettedmarks = require('../models/gettedmarks');
const xlsx = require('xlsx');
const { Op } = require('sequelize');

// Upload student CPI/SPI data from Excel file
exports.uploadStudentCPI = async (req, res) => {
    try {
        // Set up global error handler for all async operations
        process.on('unhandledRejection', (error) => {
            console.error('Unhandled Promise Rejection:', error);
        });
        if (!req.file) {
            return res.status(400).json({ message: 'Please upload an Excel file' });
        }

        console.log('Received file:', req.file.originalname, 'Size:', req.file.size, 'bytes');

        console.log('Processing file:', req.file.originalname);

        // Simple XLSX parsing - more reliable for basic Excel files
        const workbook = xlsx.read(req.file.buffer, {
            type: 'buffer',
            raw: true
        });

        console.log('Worksheet names:', workbook.SheetNames);

        if (workbook.SheetNames.length === 0) {
            return res.status(400).json({ message: 'Excel file contains no worksheets' });
        }

        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];

        // Try simplified approach - direct to JSON with header:1 option
        const simpleData = xlsx.utils.sheet_to_json(sheet, {
            header: 1,  // Use first row as headers
            raw: true,   // Keep raw values
            defval: null // Default to null for empty cells
        });

        console.log('Raw data from Excel:', simpleData);

        if (!simpleData || simpleData.length < 2) {
            return res.status(400).json({ message: 'Excel file must have a header row and at least one data row' });
        }

        // Extract header row and convert to proper case for expected columns
        const headerRow = simpleData[0];
        console.log('Header row:', headerRow);

        // Map data using simple array approach
        const expectedHeaders = ['BatchId', 'SemesterId', 'EnrollmentNumber', 'CPI', 'SPI', 'Rank'];

        // Find header indexes
        const headerIndexes = {};
        expectedHeaders.forEach(expectedHeader => {
            const index = headerRow.findIndex(h =>
                h && typeof h === 'string' &&
                h.trim().toLowerCase() === expectedHeader.toLowerCase());

            if (index !== -1) {
                headerIndexes[expectedHeader] = index;
            }
        });

        console.log('Found header indexes:', headerIndexes);

        // Check if all required headers were found
        const missingHeaders = expectedHeaders.filter(header => headerIndexes[header] === undefined);

        if (missingHeaders.length > 0) {
            return res.status(400).json({
                message: `Missing required columns: ${missingHeaders.join(', ')}`,
                foundHeaders: headerRow,
                expected: expectedHeaders
            });
        }

        // Process data rows into objects with the expected property names
        const processedData = [];
        for (let i = 1; i < simpleData.length; i++) {
            const row = simpleData[i];
            if (!row || row.length === 0) continue;

            const dataObj = {};
            expectedHeaders.forEach(header => {
                dataObj[header] = row[headerIndexes[header]];
            });

            // Skip rows with all empty values
            if (Object.values(dataObj).some(v => v !== null && v !== undefined)) {
                processedData.push(dataObj);
            }
        }

        console.log('Processed data:', processedData);

        if (processedData.length === 0) {
            return res.status(400).json({ message: 'No valid data rows found in Excel file' });
        }

        // Skip the detailed old parsing methods since we're using the simpler approach now

        // Process and save data
        const results = {
            success: 0,
            failed: 0,
            errors: []
        };

        for (const row of processedData) {
            try {
                // Get values from the row with exact column names
                const batchId = row.BatchId;
                const semesterId = row.SemesterId;
                const enrollmentNumber = row.EnrollmentNumber;
                const cpi = row.CPI;
                const spi = row.SPI;
                const rank = row.Rank;

                // Log the row data for debugging
                console.log('Processing row:', { batchId, semesterId, enrollmentNumber, cpi, spi, rank });

                // Validate all required fields are present and not undefined
                if (batchId === undefined || semesterId === undefined ||
                    enrollmentNumber === undefined || cpi === undefined ||
                    spi === undefined || rank === undefined) {
                    results.failed++;
                    results.errors.push(`Row has undefined values: ${JSON.stringify(row)}`);
                    continue;
                }

                // First, try to find if the batchId is actually a batch name
                let batch;
                let actualBatchId = batchId;

                // Check if batchId is a number or string
                if (isNaN(Number(batchId))) {
                    // If it's a string, try to find batch by name
                    console.log(`Trying to find batch by name: ${batchId}`);
                    batch = await Batch.findOne({
                        where: { batchName: batchId }
                    });

                    if (batch) {
                        console.log(`Found batch with name ${batchId}, ID: ${batch.id}`);
                        actualBatchId = batch.id;
                    }
                } else {
                    // If it's a number, try to find by ID
                    batch = await Batch.findByPk(batchId);
                }

                if (!batch) {
                    results.failed++;
                    results.errors.push(`Batch with ID/name ${batchId} not found for enrollment ${enrollmentNumber}`);
                    continue;
                }

                // Similar approach for semester - check if it's a number or name
                let semester;
                let actualSemesterId = semesterId;

                // Check if semesterId is a number or string
                if (isNaN(Number(semesterId))) {
                    // If it's a string, try to find semester by number and batch
                    console.log(`Trying to find semester by name/number: ${semesterId} for batch ${actualBatchId}`);
                    // Try to extract semester number if it's in format like "Semester 1"
                    const semNumberMatch = semesterId.match(/\d+/);
                    if (semNumberMatch) {
                        const semNumber = parseInt(semNumberMatch[0], 10);
                        semester = await Semester.findOne({
                            where: {
                                batchId: actualBatchId,
                                semesterNumber: semNumber
                            }
                        });

                        if (semester) {
                            console.log(`Found semester ${semNumber} for batch ${actualBatchId}, ID: ${semester.id}`);
                            actualSemesterId = semester.id;
                        }
                    }
                } else {
                    // If it's a number, first try direct lookup
                    semester = await Semester.findByPk(semesterId);

                    // If not found, try looking up by semester number for this batch
                    if (!semester) {
                        semester = await Semester.findOne({
                            where: {
                                batchId: actualBatchId,
                                semesterNumber: semesterId
                            }
                        });

                        if (semester) {
                            console.log(`Found semester by number ${semesterId} for batch ${actualBatchId}, ID: ${semester.id}`);
                            actualSemesterId = semester.id;
                        }
                    }
                }

                if (!semester) {
                    results.failed++;
                    results.errors.push(`Semester with ID/number ${semesterId} not found for batch ${batchId} and enrollment ${enrollmentNumber}`);
                    continue;
                }

                // Check if record already exists - use actual IDs found from lookups
                const existingRecord = await StudentCPI.findOne({
                    where: {
                        BatchId: actualBatchId,
                        SemesterId: actualSemesterId,
                        EnrollmentNumber: enrollmentNumber
                    }
                });

                if (existingRecord) {
                    // Update existing record
                    await existingRecord.update({
                        CPI: cpi,
                        SPI: spi,
                        Rank: rank
                    });
                    console.log(`Updated record for ${enrollmentNumber}`);
                } else {
                    // Create new record with correct IDs
                    await StudentCPI.create({
                        BatchId: actualBatchId, // Use the actual batch ID from lookup
                        SemesterId: actualSemesterId, // Use the actual semester ID from lookup
                        EnrollmentNumber: enrollmentNumber,
                        CPI: cpi,
                        SPI: spi,
                        Rank: rank
                    });
                    console.log(`Created new record for ${enrollmentNumber} with BatchId=${actualBatchId}, SemesterId=${actualSemesterId}`);
                }

                results.success++;
            } catch (error) {
                results.failed++;
                results.errors.push(`Error processing row for ${row.EnrollmentNumber}: ${error.message}`);
            }
        }

        return res.status(200).json({
            message: 'Excel data processed',
            results
        });
    } catch (error) {
        console.error('Error uploading student CPI data:', error);
        // Send detailed error for debugging
        return res.status(500).json({
            message: 'Server error',
            error: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
            name: error.name
        });
    } finally {
        // Clean up error handler
        process.removeListener('unhandledRejection', (error) => {
            console.error('Unhandled Promise Rejection:', error);
        });
    }
};

// Get all student CPI/SPI data
exports.getAllStudentCPI = async (req, res) => {
    try {
        const studentCPIs = await StudentCPI.findAll({
            include: [
                { model: Batch },
                { model: Semester }
            ]
        });

        return res.status(200).json(studentCPIs);
    } catch (error) {
        console.error('Error fetching student CPI data:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Get student CPI/SPI data by batch
exports.getStudentCPIByBatch = async (req, res) => {
    try {
        const { batchId } = req.params;

        const studentCPIs = await StudentCPI.findAll({
            where: { BatchId: batchId },
            include: [
                { model: Batch },
                { model: Semester }
            ]
        });

        return res.status(200).json(studentCPIs);
    } catch (error) {
        console.error('Error fetching student CPI data by batch:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Get student CPI/SPI data by enrollment number
exports.getStudentCPIByEnrollment = async (req, res) => {
    try {
        const { enrollmentNumber } = req.params;
        console.log(`Searching for student CPI data with enrollment number: ${enrollmentNumber}`);

        const studentCPIs = await StudentCPI.findAll({
            where: { EnrollmentNumber: enrollmentNumber },
            include: [
                { model: Batch },
                { model: Semester }
            ],
            order: [
                [{ model: Semester }, 'semesterNumber', 'ASC']
            ]
        });

        console.log(`Found ${studentCPIs.length} records for enrollment number: ${enrollmentNumber}`);

        if (studentCPIs.length === 0) {
            // If no records found, let's check if the enrollment number exists in the database
            const allEnrollments = await StudentCPI.findAll({
                attributes: ['EnrollmentNumber'],
                group: ['EnrollmentNumber']
            });

            console.log('Available enrollment numbers in database:',
                allEnrollments.map(e => e.EnrollmentNumber));
        }
        return res.status(200).json(studentCPIs);
    } catch (error) {
        console.error('Error fetching student CPI data by enrollment:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Add test data for a specific enrollment number
exports.addTestData = async (req, res) => {
    try {
        const { enrollmentNumber } = req.params;
        console.log(`Adding test data for enrollment number: ${enrollmentNumber}`);

        // First check if the batch exists
        const batch = await Batch.findOne({ where: { batchName: 'Degree 22-26' } });
        if (!batch) {
            return res.status(404).json({ message: 'Batch not found' });
        }

        // Get all semesters for this batch
        const semesters = await Semester.findAll({
            where: { batchId: batch.id },
            order: [['semesterNumber', 'ASC']]
        });

        if (semesters.length === 0) {
            return res.status(404).json({ message: 'No semesters found for this batch' });
        }

        // Create test data for each semester
        const createdRecords = [];

        for (let i = 0; i < semesters.length; i++) {
            const semester = semesters[i];

            // Generate random CPI and SPI values (between 6 and 9.5)
            const spi = (6 + Math.random() * 3.5).toFixed(2);

            // CPI is the average of all SPIs up to this point
            // For simplicity, we'll make it slightly different from SPI
            const cpi = (parseFloat(spi) + (Math.random() * 0.4 - 0.2)).toFixed(2);

            // Random rank between 1 and 50
            const rank = Math.floor(Math.random() * 50) + 1;

            const record = await StudentCPI.create({
                BatchId: batch.id,
                SemesterId: semester.id,
                EnrollmentNumber: enrollmentNumber,
                CPI: cpi,
                SPI: spi,
                Rank: rank
            });

            createdRecords.push(record);
        }

        return res.status(201).json({
            message: `Created ${createdRecords.length} test records for enrollment number ${enrollmentNumber}`,
            records: createdRecords
        });
    } catch (error) {
        console.error('Error adding test data:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.getStudentCPIByEmail = async (req, res) => {
    try {
        const { email } = req.params;
        // Fetch student by email
        const student = await Student.findOne({
            where: { email }
        });

        if (!student) {
            return res.status(404).json({ message: 'Student not found' });
        }

        console.log('Found student:', student.dataValues);

        try {
            const enrollmentNumber = student.enrollmentNumber;

            const studentCPIs = await StudentCPI.findAll({
                where: {
                    EnrollmentNumber: enrollmentNumber
                },
                include: [{
                    model: Semester,
                    attributes: ['semesterNumber'],
                    required: true
                }],
                order: [['SemesterId', 'ASC']]
            });

            if (studentCPIs.length === 0) {
                return res.status(404).json({
                    message: 'No CPI records found for this student',
                    studentInfo: {
                        name: student.name,
                        enrollmentNumber: student.enrollmentNumber,
                        email: student.email,
                        currentSemester: student.currnetsemester
                    }
                });
            }

            // Transform the response to include semester number
            const transformedCPIs = studentCPIs.map(cpi => ({
                id: cpi.id,
                BatchId: cpi.BatchId,
                SemesterId: cpi.SemesterId,
                semesterNumber: cpi.Semester.semesterNumber,
                EnrollmentNumber: cpi.EnrollmentNumber,
                CPI: cpi.CPI,
                SPI: cpi.SPI,
                Rank: cpi.Rank,
                createdAt: cpi.createdAt,
                updatedAt: cpi.updatedAt
            }));

            // Return all CPI records for this student with semester numbers
            return res.status(200).json(transformedCPIs);

        } catch (error) {
            console.error('Error fetching student CPI data by enrollment:', error);
            return res.status(500).json({ message: 'Server error', error: error.message });
        }
    } catch (error) {
        console.error('Error fetching student CPI data by email:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};


exports.getStudentComponentMarksAndSubjectsByEmail = async (req, res) => {
    try {
        const { email } = req.body;

        // Find student by email
        const student = await Student.findOne({
            where: { email },
            include: [{ model: Batch }]
        });

        if (!student) {
            return res.status(404).json({ message: 'Student not found with this email' });
        }

        // Get all semesters for the student's batch
        const semesters = await Semester.findAll({
            where: { batchId: student.batchId },
            order: [['semesterNumber', 'ASC']]
        });

        if (!semesters || semesters.length === 0) {
            return res.status(404).json({ message: 'No semesters found for this student' });
        }

        // Get all student CPI records
        const cpiRecords = await StudentCPI.findAll({
            where: { enrollmentNumber: student.enrollmentNumber },
            include: [{ model: Semester }],
            order: [[Semester, 'semesterNumber', 'ASC']]
        });

        // Prepare response data
        const semesterData = [];

        for (const semester of semesters) {
            // Find subjects for this semester and batch
            const subjects = await Subject.findAll({
                where: {
                    semesterId: semester.id,
                    batchId: student.batchId
                }
            });

            const subjectsWithMarks = [];

            // Log the subjects for debugging
            console.log('Subjects found:', subjects);

            for (const subject of subjects) {
                // Check if we have all required fields
                if (!subject || !subject.subjectName) {
                    console.log('Invalid subject data:', subject);
                    continue;
                }

                // Try to find matching unique subject 
                // Note: We're using a direct query instead of relying on a foreign key relationship
                const uniqueSubjects = await UniqueSubDegree.findAll();
                const uniqueSubject = uniqueSubjects.find(us =>
                    us.sub_name.toLowerCase() === subject.subjectName.toLowerCase());

                if (!uniqueSubject) {
                    console.log(`No matching UniqueSubDegree found for subject: ${subject.subjectName}`);
                    continue;
                }

                const subCode = uniqueSubject.sub_code;
                console.log(`Found matching subject code: ${subCode} for subject: ${subject.subjectName}`);

                // Get component marks for this subject and student
                const componentMarks = await ComponentMarks.findAll({
                    where: { subjectId: subCode }
                });

                // Get student's specific marks
                const studentMarks = await Gettedmarks.findOne({
                    where: {
                        studentId: student.id,
                        subjectId: subCode
                    }
                });

                // Get component weightage
                const componentWeightage = await ComponentWeightage.findOne({
                    where: { subjectId: subCode }
                });

                subjectsWithMarks.push({
                    subjectId: subject.id,
                    subjectCode: uniqueSubject.sub_code,
                    subjectName: uniqueSubject.sub_name,
                    credits: uniqueSubject.sub_credit, // Using the correct field name from UniqueSubDegree model
                    componentMarks: studentMarks ? {
                        ese: studentMarks.ese,
                        cse: studentMarks.cse,
                        ia: studentMarks.ia,
                        tw: studentMarks.tw,
                        viva: studentMarks.viva
                    } : null,
                    componentWeightage: componentWeightage ? {
                        ese: componentWeightage.ese,
                        cse: componentWeightage.cse,
                        ia: componentWeightage.ia,
                        tw: componentWeightage.tw,
                        viva: componentWeightage.viva
                    } : null,
                    grades: studentMarks ? studentMarks.grades : null // Include grades from gettedmarks
                });
            }

            // Find CPI/SPI for this semester
            const semesterCPI = cpiRecords.find(record => record.semesterId === semester.id);

            semesterData.push({
                semesterId: semester.id,
                semesterNumber: semester.semesterNumber,
                startDate: semester.startDate,
                endDate: semester.endDate,
                cpi: semesterCPI ? semesterCPI.cpi : null,
                spi: semesterCPI ? semesterCPI.spi : null,
                rank: semesterCPI ? semesterCPI.rank : null,
                subjects: subjectsWithMarks
            });
        }

        return res.status(200).json({
            student: {
                id: student.id,
                name: student.name,
                email: student.email,
                enrollmentNumber: student.enrollmentNumber,
                batch: student.Batch.batchName,

            },
            semesters: semesterData
        });

    } catch (error) {
        console.error('Error fetching student component marks and subjects:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};
