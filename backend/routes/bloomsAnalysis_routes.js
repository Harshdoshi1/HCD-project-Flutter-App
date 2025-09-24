const express = require('express');
const router = express.Router();
const {
    getDetailedBloomsAchievement,
    compareBloomsAchievement,
    getCOAttainmentReport
} = require('../controller/bloomsAnalysisController');

// Get detailed Bloom's achievement for a student
// GET /api/blooms-analysis/student/:enrollmentNumber/semester/:semesterNumber
router.get('/student/:enrollmentNumber/semester/:semesterNumber', getDetailedBloomsAchievement);

// Get detailed Bloom's achievement for a student in a specific subject
// GET /api/blooms-analysis/student/:enrollmentNumber/semester/:semesterNumber/subject/:subjectId
router.get('/student/:enrollmentNumber/semester/:semesterNumber/subject/:subjectId', getDetailedBloomsAchievement);

// Compare Bloom's achievement for all students in a batch
// GET /api/blooms-analysis/compare/batch/:batchId/semester/:semesterNumber
router.get('/compare/batch/:batchId/semester/:semesterNumber', compareBloomsAchievement);

// Compare Bloom's achievement for all students in a batch for a specific subject
// GET /api/blooms-analysis/compare/batch/:batchId/semester/:semesterNumber/subject/:subjectId
router.get('/compare/batch/:batchId/semester/:semesterNumber/subject/:subjectId', compareBloomsAchievement);

// Get CO attainment report for a subject
// GET /api/blooms-analysis/co-attainment/subject/:subjectId/batch/:batchId/semester/:semesterNumber
router.get('/co-attainment/subject/:subjectId/batch/:batchId/semester/:semesterNumber', getCOAttainmentReport);

module.exports = router;
