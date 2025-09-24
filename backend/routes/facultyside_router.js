const express = require("express");
const router = express.Router();
const {
    getStudentMarksByBatchAndSubject,
    updateStudentMarks,
    getSubjectByBatchAndSemester,
    getBatchIdfromName,
    getSubjectNamefromCode

} = require("../controller/gettedmarksController");

router.post('/marks/getBatchId/:batchName', getBatchIdfromName);
router.post('/marks/getSubjectName/:subjectCode', getSubjectNamefromCode);

router.get('/marks/students/:batchName', getStudentMarksByBatchAndSubject);
router.post('/marks/update/:studentId/:subjectId', updateStudentMarks);

router.get('/marks/getsubjectByBatchAndSemester/:batchId/:semesterId/:facultyName', getSubjectByBatchAndSemester);
module.exports = router;
