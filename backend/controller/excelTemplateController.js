const xlsx = require('xlsx');

// Generate Excel template with sample data
exports.generateExcelTemplate = async (req, res) => {
    try {
        // Sample data structure
        const sampleData = [
            {
                'Enrolment': '92200133001',
                'Name': 'Ritesh Sanchala',
                'Email': 'ritesh@gmail.com',
                'BatchName': 'Degree 22-26',
                'SemesterNumber': 2,
                'Class': 'A'
            },
            {
                'Enrolment': '92200133002',
                'Name': 'Harsh Doshi',
                'Email': 'harsh@gmail.com',
                'BatchName': 'Degree 22-26',
                'SemesterNumber': 2,
                'Class': 'B'
            },
            {
                'Enrolment': '92200133003',
                'Name': 'Sample Student',
                'Email': 'sample@example.com',
                'BatchName': 'Degree 22-26',
                'SemesterNumber': 2,
                'Class': 'A'
            }
        ];

        // Create workbook and worksheet
        const workbook = xlsx.utils.book_new();
        const worksheet = xlsx.utils.json_to_sheet(sampleData);

        // Set column widths
        const columnWidths = [
            { wch: 15 }, // Enrolment
            { wch: 20 }, // Name
            { wch: 25 }, // Email
            { wch: 20 }, // BatchName
            { wch: 15 }, // SemesterNumber
            { wch: 10 }  // Class
        ];
        worksheet['!cols'] = columnWidths;

        // Add worksheet to workbook
        xlsx.utils.book_append_sheet(workbook, worksheet, 'Student List Template');

        // Generate buffer
        const buffer = xlsx.write(workbook, { type: 'buffer', bookType: 'xlsx' });

        // Set response headers
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename="student_list_template.xlsx"');
        res.setHeader('Content-Length', buffer.length);

        // Send the file
        res.send(buffer);

    } catch (error) {
        console.error('Error generating Excel template:', error);
        res.status(500).json({
            success: false,
            message: 'Error generating Excel template',
            error: error.message
        });
    }
};

// Get Excel format instructions
exports.getExcelFormatInstructions = async (req, res) => {
    try {
        const instructions = {
            success: true,
            data: {
                requiredColumns: [
                    {
                        name: 'Enrolment',
                        description: 'Student enrollment number (unique identifier)',
                        example: '92200133001',
                        required: true
                    },
                    {
                        name: 'Name',
                        description: 'Full name of the student',
                        example: 'Ritesh Sanchala',
                        required: true
                    },
                    {
                        name: 'Email',
                        description: 'Student email address',
                        example: 'ritesh@gmail.com',
                        required: true
                    },
                    {
                        name: 'BatchName',
                        description: 'Name of the batch',
                        example: 'Degree 22-26',
                        required: true
                    },
                    {
                        name: 'SemesterNumber',
                        description: 'Current semester number',
                        example: '2',
                        required: true
                    },
                    {
                        name: 'Class',
                        description: 'Class section (A, B, C, etc.)',
                        example: 'A',
                        required: true
                    }
                ],
                formatRequirements: [
                    'First row must contain column headers exactly as shown above',
                    'Data should start from the second row',
                    'Enrollment numbers must be unique',
                    'Email addresses must be in valid format',
                    'Semester numbers must be integers',
                    'Class names should match the class configuration'
                ],
                notes: [
                    'The system will automatically update student class names based on this Excel file',
                    'Only students with existing enrollment numbers will be updated',
                    'Empty rows will be automatically skipped',
                    'File size limit: 5MB'
                ]
            }
        };

        res.status(200).json(instructions);

    } catch (error) {
        console.error('Error getting format instructions:', error);
        res.status(500).json({
            success: false,
            message: 'Error getting format instructions',
            error: error.message
        });
    }
};
