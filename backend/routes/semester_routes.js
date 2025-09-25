const express = require('express');
const router = express.Router();

const {
    addSemester,
    getSemestersByBatch,
    getSemestersByBatchId,
    getSemesterIdByNumber,
    getSemesterNumberById
} = require('../controller/semesterController.js');

// Semester Routes
router.post('/addSemester', addSemester);
router.get('/getSemestersByBatch/:batchName', getSemestersByBatch);
// New route matching frontend usage: /api/semesters/batch/:batchId
router.get('/batch/:batchId', getSemestersByBatchId);
router.get('/semesters/batch/:batchId', getSemestersByBatchId);

// router.get('/getSemestersByBatch', getSemestersByBatch);
router.get('/id/:semesterNumber', getSemesterIdByNumber);
router.get("/getSemesterNumberById/:semesterId", getSemesterNumberById);


module.exports = router;