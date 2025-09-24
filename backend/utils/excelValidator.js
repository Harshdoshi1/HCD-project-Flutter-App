// Excel data validation utilities

const validateExcelHeaders = (headers) => {
    console.log('Validating headers:', headers);

    const requiredColumns = [
        { key: 'enrollment', aliases: ['enrolment', 'enrollment', 'enrollment number', 'enrolment number'] },
        { key: 'name', aliases: ['name', 'student name', 'full name'] },
        { key: 'email', aliases: ['email', 'email address', 'student email'] },
        { key: 'batchName', aliases: ['batchname', 'batch name', 'batch'] },
        { key: 'semesterNumber', aliases: ['semesternumber', 'semester number', 'semester'] },
        { key: 'class', aliases: ['class', 'class name', 'section'] }
    ];

    const foundColumns = {};
    const missingColumns = [];

    headers.forEach((header, index) => {
        if (!header) return;

        const headerStr = header.toString().toLowerCase().trim();
        console.log(`Processing header "${header}" -> "${headerStr}"`);

        for (const column of requiredColumns) {
            if (column.aliases.some(alias => headerStr.includes(alias))) {
                foundColumns[column.key] = index;
                console.log(`Found column "${column.key}" at index ${index}`);
                break;
            }
        }
    });

    // Check for missing required columns
    for (const column of requiredColumns) {
        if (!foundColumns[column.key]) {
            missingColumns.push(column.key);
        }
    }

    const result = {
        isValid: missingColumns.length === 0,
        columnIndices: foundColumns,
        missingColumns,
        headers: headers
    };

    console.log('Validation result:', result);
    return result;
};

const validateStudentData = (student, rowIndex) => {
    const errors = [];

    if (!student.enrollmentNumber || student.enrollmentNumber.trim() === '') {
        errors.push(`Row ${rowIndex + 1}: Missing enrollment number`);
    }

    if (!student.name || student.name.trim() === '') {
        errors.push(`Row ${rowIndex + 1}: Missing student name`);
    }

    if (!student.email || student.email.trim() === '') {
        errors.push(`Row ${rowIndex + 1}: Missing email address`);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (student.email && !emailRegex.test(student.email)) {
        errors.push(`Row ${rowIndex + 1}: Invalid email format`);
    }

    if (!student.batchName || student.batchName.trim() === '') {
        errors.push(`Row ${rowIndex + 1}: Missing batch name`);
    }

    if (!student.semesterNumber || isNaN(student.semesterNumber)) {
        errors.push(`Row ${rowIndex + 1}: Invalid semester number`);
    }

    if (!student.className || student.className.trim() === '') {
        errors.push(`Row ${rowIndex + 1}: Missing class name`);
    }

    return {
        isValid: errors.length === 0,
        errors
    };
};

const sanitizeStudentData = (student) => {
    return {
        enrollmentNumber: student.enrollmentNumber?.toString().trim() || '',
        name: student.name?.toString().trim() || '',
        email: student.email?.toString().trim().toLowerCase() || '',
        batchName: student.batchName?.toString().trim() || '',
        semesterNumber: student.semesterNumber ? parseInt(student.semesterNumber) : null,
        className: student.className?.toString().trim() || ''
    };
};

module.exports = {
    validateExcelHeaders,
    validateStudentData,
    sanitizeStudentData
};
