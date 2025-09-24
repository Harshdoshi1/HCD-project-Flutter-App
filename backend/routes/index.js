const express = require('express');
const router = express.Router();
const eventsRouter = require('./events');
const eventOutcomeRouter = require('./eventOutcomeRoutes');
const excelUploadRouter = require('./excelUploadRoutes');

// Event routes
router.use('/events', eventsRouter);

// Event Outcomes routes
router.use('/event-outcomes', eventOutcomeRouter);

// Excel Upload routes
router.use('/excel-upload', excelUploadRouter);

module.exports = router;
