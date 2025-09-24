const express = require('express');
const router = express.Router();
const {
    createEvent,
    insertFetchedStudents,
    getAllEventnames,
    getAllCoCurricularEventsNames,
    getAllExtraCurricularEventsNames,
    getAllParticipationTypes,
    insertIntoStudentPoints,
    fetchEventsbyEnrollandSemester,
    fetchEventsIDsbyEnroll,
    fetchEventsByIds,
    fetchEventsByEventIds,
    fetchTotalActivityPoints
} = require('../controller/StudentEventController');

// Add new event
router.post('/', createEvent);

// Update existing event
// router.put('/:activityId', updateActivity);

// Get all event names
router.get('/all', getAllEventnames);
router.post('/uploadExcell', insertFetchedStudents);
router.get('/allCoCurricularnames', getAllCoCurricularEventsNames);
router.get('/allExtraCurricularnames', getAllExtraCurricularEventsNames);
router.get('/allParticipationTypes', getAllParticipationTypes);
router.post('/insertIntoStudentPoints', insertIntoStudentPoints);
router.post('/fetchEventsbyEnrollandSemester', fetchEventsbyEnrollandSemester);
router.post('/fetchEventsIDsbyEnroll', fetchEventsIDsbyEnroll);
router.post('/fetchEventsByIds', fetchEventsByIds);
router.post('/fetchEventsByEventIds', fetchEventsByEventIds);
router.post('/fetchTotalActivityPoints', fetchTotalActivityPoints);
// Insert fetched students into database
router.post('/students', insertFetchedStudents);
module.exports = router;
