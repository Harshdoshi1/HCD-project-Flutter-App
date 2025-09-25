const express = require('express');
const router = express.Router();
const { 
    getStudentAnalysisData, 
    getSubjectWisePerformance, 
    getBloomsTaxonomyDistribution 
} = require('../controller/studentAnalysisController');

// Route to get comprehensive student analysis data
router.get('/comprehensive/:enrollmentNumber/:semesterNumber', getStudentAnalysisData);

// Route to get subject-wise performance data for academic analysis
router.get('/performance/:enrollmentNumber/:semesterNumber', getSubjectWisePerformance);

// Route to get Bloom's taxonomy distribution for a student
router.get('/blooms/:enrollmentNumber/:semesterNumber', getBloomsTaxonomyDistribution);

module.exports = router;
