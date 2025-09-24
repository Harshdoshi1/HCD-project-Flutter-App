const express = require('express');
const router = express.Router();
const subjectComponentCoController = require('../controller/subjectComponentCoController');
// const authMiddleware = require('../middleware/authMiddleware'); // If you have auth

// Get all COs for a specific subject component
router.get('/component/:subjectComponentId', subjectComponentCoController.getCOsBySubjectComponent);

// Get all subject components for a specific CO
router.get('/co/:courseOutcomeId', subjectComponentCoController.getSubjectComponentsByCO);

// Add authMiddleware if routes need protection
// router.post('/', authMiddleware, subjectComponentCoController.linkCoToComponent); // Example

module.exports = router;
