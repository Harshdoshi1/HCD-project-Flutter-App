const express = require('express');
const {
    getSubjects,
    getDropdownData,
    assignSubject,
    getSubjectsByBatchSemesterandFaculty,
    addUniqueSubDegree,
    addUniqueSubDiploma,
    addSubjectWithComponents,
    getSubjectWithComponents,
    getSubjectComponentsWithSubjectCode,
    addSubject,
    getSubjectByCode,
    deleteSubject,
    getSubjectsByBatchAndSemester,
    getAllUniqueSubjects,
    getSubjectsByBatch,
    getAllSubjectsWithDetails,
    getSubjectsByBatchWithDetails,
    getSubjectsByBatchAndSemesterWithDetails
} = require('../controller/subController');

const router = express.Router();


router.post('/addSubject', addSubject);
router.get('/getSubjectByCode', getSubjectByCode);
router.get("/getSubjects/:batchName/:semesterNumber", getSubjectsByBatchAndSemester);

// router.get('/getSubjects', getSubjects);
router.get('/getDropdownData', getDropdownData);
router.post('/assignSubject', assignSubject);
router.post('/getSubjectsByBatchSemesterandFaculty', getSubjectsByBatchSemesterandFaculty);


router.post('/addUniqueSubDegree', addUniqueSubDegree);
router.post('/addUniqueSubDiploma', addUniqueSubDiploma);


router.post("/addSubjectWithComponents", addSubjectWithComponents);
router.get("/subject/:subjectCode", getSubjectWithComponents);

router.get("/getSubjectComponentsWithSubjectCode/:subjectCode", getSubjectComponentsWithSubjectCode);

router.get('/getAllUniqueSubjects', getAllUniqueSubjects);
router.get('/getSubjectsByBatch/:batchName', getSubjectsByBatch);

router.get('/getAllSubjectsWithDetails', getAllSubjectsWithDetails);
router.get('/getSubjectsByBatchWithDetails/:batchName', getSubjectsByBatchWithDetails);
router.get('/getSubjectsByBatchAndSemesterWithDetails/:batchName/:semesterNumber', getSubjectsByBatchAndSemesterWithDetails);

router.delete("/deleteSubjectbycode", deleteSubject);

module.exports = router;
