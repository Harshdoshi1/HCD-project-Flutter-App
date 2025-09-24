# Excel Upload and Class Management System

This document describes the Excel upload functionality for managing student class assignments in the HCD project.

## Overview

The system allows HODs to:
1. Upload Excel files containing student information
2. Automatically update student class names based on Excel data
3. Preview Excel data before uploading
4. Download Excel templates and format instructions
5. Track upload history for each class

## Database Schema Updates

### Students Table
- Added `currentClassName` column to store the current class assignment

### SubjectWiseGrades Table
- Added `className` column to track which class the grade was recorded for

### StudentCPIs Table
- Added `className` column to track which class the CPI was recorded for

### ClassSections Table
- Added `excelFileName` and `studentCount` columns to track Excel uploads

## Excel File Format

### Required Columns
The Excel file must contain these columns (case-insensitive):

| Column | Description | Example | Required |
|--------|-------------|---------|----------|
| Enrolment | Student enrollment number | 92200133001 | Yes |
| Name | Student full name | Ritesh Sanchala | Yes |
| Email | Student email address | ritesh@gmail.com | Yes |
| BatchName | Batch name | Degree 22-26 | Yes |
| SemesterNumber | Current semester | 2 | Yes |
| Class | Class section | A | Yes |

### Sample Data
```
Enrolment    | Name            | Email              | BatchName      | SemesterNumber | Class
92200133001  | Ritesh Sanchala | ritesh@gmail.com   | Degree 22-26   | 2              | A
92200133002  | Harsh Doshi     | harsh@gmail.com    | Degree 22-26   | 2              | B
```

## API Endpoints

### Excel Upload
- `POST /api/excel-upload/upload` - Upload and process Excel file
- `POST /api/excel-upload/preview` - Preview Excel data without updating
- `GET /api/excel-upload/history/:className/:semesterId/:batchId` - Get upload history

### Excel Templates
- `GET /api/excel-upload/template` - Download Excel template
- `GET /api/excel-upload/instructions` - Get format instructions

## Frontend Features

### ManageBatches.jsx
- **Excel File Upload**: Choose Excel files for each class
- **Preview Button**: View Excel data before uploading
- **Upload Button**: Process Excel and update student class names
- **Template Download**: Download sample Excel template
- **Format Guide**: View detailed format instructions

### Excel Actions
- **File Selection**: Drag & drop or click to choose Excel files
- **Validation**: Real-time validation of Excel format
- **Progress Tracking**: Loading states during upload
- **Error Handling**: Clear error messages for validation issues

## Workflow

### 1. Create Class Configuration
1. Navigate to "Add Semester" tab
2. Select batch and semester
3. Set number of classes (creates A, B, C, etc.)
4. Name each class (e.g., "Computer Science A")

### 2. Upload Student Data
1. Click "Download Template" to get sample Excel
2. Fill in student information following the template
3. Select the Excel file for each class
4. Click "Preview" to verify data
5. Click "Upload" to update student class names

### 3. Data Processing
- System parses Excel file and validates data
- Finds students by enrollment number
- Updates `currentClassName` in Students table
- Records upload history in ClassSections table

## Validation Rules

### Excel Headers
- Must contain all required columns
- Column names are case-insensitive
- Supports common variations (e.g., "Enrolment" vs "Enrollment")

### Student Data
- Enrollment numbers must be unique and non-empty
- Email addresses must be in valid format
- Names cannot be empty
- Batch names must match existing batches
- Semester numbers must be integers
- Class names must match class configuration

### File Requirements
- File size: Maximum 5MB
- Format: .xlsx or .xls
- Structure: Headers in first row, data from second row

## Error Handling

### Validation Errors
- Missing required columns
- Invalid data formats
- Empty required fields
- Duplicate enrollment numbers

### Processing Errors
- Students not found in database
- Database connection issues
- File parsing errors

### User Feedback
- Clear error messages with row numbers
- Success confirmations with update counts
- Loading states during operations

## Security Features

### File Validation
- File type verification
- Size limits
- Content validation before processing

### Data Sanitization
- Input sanitization
- SQL injection prevention
- Transaction-based updates

## Benefits

### For HODs
- **Efficient Management**: Bulk update student class assignments
- **Data Accuracy**: Automated validation prevents errors
- **Template System**: Clear format requirements
- **Preview Functionality**: Verify data before committing

### For System
- **Data Consistency**: Centralized class management
- **Audit Trail**: Track all class changes
- **Scalability**: Handle large student populations
- **Integration**: Seamless connection with existing systems

## Technical Implementation

### Backend
- **Multer**: File upload handling
- **XLSX**: Excel file parsing
- **Sequelize**: Database operations
- **Validation**: Comprehensive data validation

### Frontend
- **React Hooks**: State management
- **FormData**: File upload handling
- **Error Boundaries**: Graceful error handling
- **Responsive Design**: Mobile-friendly interface

## Usage Instructions

### Step 1: Prepare Excel File
1. Download the template from the system
2. Fill in student information
3. Ensure all required columns are present
4. Verify data accuracy

### Step 2: Upload to System
1. Select the class in ManageBatches
2. Choose the Excel file
3. Preview the data
4. Upload to update student records

### Step 3: Verify Updates
1. Check student records in the system
2. Verify class assignments are correct
3. Review upload history if needed

## Troubleshooting

### Common Issues
- **File Not Uploading**: Check file size and format
- **Validation Errors**: Verify column names and data
- **Students Not Found**: Ensure enrollment numbers exist in database
- **Upload Failures**: Check database connection and permissions

### Support
- Use the format guide for detailed instructions
- Download the template for correct structure
- Preview data before uploading
- Check error messages for specific issues
