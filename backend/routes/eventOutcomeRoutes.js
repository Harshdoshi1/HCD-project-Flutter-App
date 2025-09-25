const express = require('express');
const router = express.Router();
const eventOutcomeController = require('../controller/eventOutcomeController');

// Get all event outcomes
router.get('/', eventOutcomeController.getAllEventOutcomes);

// Get event outcomes by type (Technical/Non-Technical)
router.get('/type/:outcomeType', eventOutcomeController.getEventOutcomesByType);

// Create a new event outcome
router.post('/', eventOutcomeController.createEventOutcome);

// Update an event outcome
router.put('/:id', eventOutcomeController.updateEventOutcome);

// Delete an event outcome
router.delete('/:id', eventOutcomeController.deleteEventOutcome);

module.exports = router;