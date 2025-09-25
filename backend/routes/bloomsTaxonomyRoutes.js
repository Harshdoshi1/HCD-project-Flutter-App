const express = require('express');
const router = express.Router();
const bloomsTaxonomyController = require('../controller/bloomsTaxonomyController');

// Get all Blooms Taxonomy levels
router.get('/', bloomsTaxonomyController.getAllBloomsLevels);

// Create new Blooms Taxonomy level
router.post('/', bloomsTaxonomyController.createBloomsLevel);

// Create multiple Blooms Taxonomy levels
router.post('/bulk', bloomsTaxonomyController.createBloomsLevels);

// Associate Blooms Taxonomy levels with a Course Outcome
router.post('/associate', bloomsTaxonomyController.associateBloomsWithCO);

// Get Blooms Taxonomy levels for a Course Outcome
router.get('/co/:courseOutcomeId', bloomsTaxonomyController.getBloomsForCO);

module.exports = router; 