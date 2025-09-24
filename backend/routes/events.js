// const express = require('express');
// const router = express.Router();
// const multer = require('multer');
// // const eventController = require('../controller/eventController');]
// const {eventController} = require('../controller/StudentEventController');
// const { createEvent } = require('../controller/StudentEventController');

// // Configure multer for file uploads
// const upload = multer({
//   dest: 'uploads/',
//   limits: {
//     fileSize: 1024 * 1024 * 5 // 5MB limit
//   },
//   fileFilter: (req, file, cb) => {
//     if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
//       cb(null, true);
//     } else {
//       cb(new Error('Only .xlsx files are allowed!'));
//     }
//   }
// });

// // Event management routes
// router.get('/all', eventController.getAllEvents);
// router.get('/:eventId', eventController.getEventById);
// router.post('/createEvent', eventController.createEvent);
// router.put('/:eventId', eventController.updateEvent);
// router.delete('/:eventId', eventController.deleteEvent);

// // Student event routes (existing) - moved to avoid conflict
// router.post('/student-event', createEvent);

// module.exports = router;

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
