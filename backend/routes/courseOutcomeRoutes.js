const express = require('express');
const router = express.Router();
const courseOutcomeController = require('../controller/courseOutcomeController');

// Get all course outcomes for a specific subject
router.get('/subject/:subjectId', courseOutcomeController.getCourseOutcomesBySubject);

// Get a specific course outcome by ID
router.get('/:id', courseOutcomeController.getCourseOutcomeById);

// Create a new course outcome
router.post('/', courseOutcomeController.createCourseOutcome);

// Update a course outcome
router.put('/:id', courseOutcomeController.updateCourseOutcome);

// Delete a course outcome
router.delete('/:id', courseOutcomeController.deleteCourseOutcome);

module.exports = router;


