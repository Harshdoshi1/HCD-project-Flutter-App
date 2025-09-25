const express = require('express');

const {
    addFaculty,
    createAssignSubject,
    getAllAssignSubjects,
    getAssignSubjectById,
    updateAssignSubject,
    deleteAssignSubject,
    getSubjectsByFaculty
} = require('../controller/facultyController'); // Ensure correct path

const router = express.Router();


// Faculty Routes
router.post('/addFaculty', addFaculty);
router.post('/createAssignSubject', createAssignSubject);
router.post('/getAllAssignSubjects', getAllAssignSubjects);
router.get('/getAssignSubjectById', getAssignSubjectById);
router.put('/updateAssignSubject', updateAssignSubject);
router.delete('/deleteAssignSubject', deleteAssignSubject);
router.get('/getSubjectsByFaculty/:facultyId', getSubjectsByFaculty);

module.exports = router; 
