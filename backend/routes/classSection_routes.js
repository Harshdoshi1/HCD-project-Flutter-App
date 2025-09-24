const express = require('express');
const router = express.Router();

const {
    addClassSections,
    getClassSectionsBySemester,
    getSemesterWiseBatchInfo,
    updateClassSection,
    deleteClassSection
} = require('../controller/classSectionController.js');

// Class Section Routes
router.post('/addClassSections', addClassSections);
router.get('/getClassSectionsBySemester/:batchName/:semesterNumber', getClassSectionsBySemester);
router.get('/getSemesterWiseBatchInfo/:batchName', getSemesterWiseBatchInfo);
router.put('/updateClassSection/:classSectionId', updateClassSection);
router.delete('/deleteClassSection/:classSectionId', deleteClassSection);

module.exports = router; 