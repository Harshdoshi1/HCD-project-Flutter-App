const express = require('express');
const router = express.Router();
const studentCPIController = require('../controller/studentCPIController');
const multer = require('multer');

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// Routes for student CPI/SPI data
router.post('/upload', upload.single('file'), studentCPIController.uploadStudentCPI);
router.get('/all', studentCPIController.getAllStudentCPI);
router.get('/batch/:batchName', studentCPIController.getStudentCPIByBatch);
router.get('/enrollment/:enrollmentNumber', studentCPIController.getStudentCPIByEnrollment);
router.get('/email/:email', studentCPIController.getStudentCPIByEmail);
router.post('/getStudentComponentMarksAndSubjectsByEmail', studentCPIController.getStudentComponentMarksAndSubjectsByEmail);

module.exports = router;
