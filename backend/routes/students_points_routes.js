const express = require('express');
const router = express.Router();

const {
    createEvent,
    insertFetchedStudents,
    getAllEventnames
} = require('../controller/StudentEventController.js');

router.post('/createEvent', createEvent);
router.post('/uploadExcell', insertFetchedStudents);
router.get('/getAllEventNames', getAllEventnames);
module.exports = router;
