const express = require('express');
const router = express.Router();
const {
    getStudentMarksWithSubComponents,
    updateStudentMarks,
    getStudentMarksForGrading,
    getSubjectComponentsForGrading,
    getExistingStudentMarks
} = require('../controller/studentMarksController');

// Get student marks with sub-components for a specific subject
router.get('/subject/:batchId/:semesterNumber/:subjectCode', getStudentMarksWithSubComponents);

// Update student marks (with sub-components support)
router.post('/update/:studentId/:subjectCode', updateStudentMarks);

// Get student marks for grading interface
router.get('/grading/:batchId/:semesterNumber', getStudentMarksForGrading);

// Get existing student marks for a specific subject and semester
router.get('/grading/:batchId/:semesterNumber/:subjectCode', getExistingStudentMarks);

// Get subject components with sub-components for grading
router.get('/components/:subjectCode', getSubjectComponentsForGrading);

module.exports = router;
