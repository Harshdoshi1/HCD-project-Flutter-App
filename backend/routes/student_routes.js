const express = require('express');
const router = express.Router();

const {
    createStudent,
    getStudentById,
    getAllStudents,
    updateStudent,
    deleteStudent,
    createStudents,
    updateStudentSemesters,
    getStudentsByBatch,
    loginStudent,
    getCurrentSemesterPoints,
    getAllStudentsCurrentSemesterPoints
} = require('../controller/studentController');

router.post('/login', loginStudent);

router.post('/createStudent', createStudent);
router.get('/getStudentById', getStudentById);
router.get('/getAllStudents', getAllStudents);
router.put('/updateStudent', updateStudent);
router.delete('/deleteStudent', deleteStudent);
router.post('/bulkUpload', createStudents);
router.post('/updateStudentSemesters', updateStudentSemesters);
router.get('/getStudentsByBatch/:batchId', getStudentsByBatch);

// Student points routes
router.get('/points/:enrollmentNumber/:semester', getCurrentSemesterPoints);
router.get('/points/allStudents/currentSemester', getAllStudentsCurrentSemesterPoints);


module.exports = router;


// const {
    //     addActivity,
    //     updateActivity,
    //     deleteActivity,
    //     getStudentActivities
    // } = require('../controller/student_cocurricular_controller');
    
// // Co-curricular Activity Routes
// router.post('/activities', addActivity);
// router.put('/activities/:activityId', updateActivity);
// router.delete('/activities/:activityId', deleteActivity);
// router.post('/activities/students', getStudentActivities);
