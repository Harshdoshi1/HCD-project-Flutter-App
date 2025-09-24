const express = require('express');
const router = express.Router();
const { 
    calculateAndStoreBloomsDistribution, 
    getStoredBloomsDistribution 
} = require('../controller/bloomsDistributionController');

// Route to calculate and store Bloom's taxonomy distribution
router.post('/calculate/:enrollmentNumber/:semesterNumber', calculateAndStoreBloomsDistribution);

// Route to get stored Bloom's taxonomy distribution
router.get('/stored/:enrollmentNumber/:semesterNumber', getStoredBloomsDistribution);

module.exports = router;
