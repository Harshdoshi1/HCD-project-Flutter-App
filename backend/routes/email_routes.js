// backend/routes/email_routes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const emailController = require('../controller/emailController');

// Configure multer for file uploads with error handling
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max file size
    }
}).single('attachment');

// Route for sending email with attachment
router.post('/send', (req, res, next) => {
    upload(req, res, function (err) {
        if (err instanceof multer.MulterError) {
            // A Multer error occurred when uploading
            console.error('Multer error during file upload:', err);
            return res.status(400).json({
                success: false,
                message: 'File upload error',
                error: err.message
            });
        } else if (err) {
            // An unknown error occurred
            console.error('Unknown error during file upload:', err);
            return res.status(500).json({
                success: false,
                message: 'Unknown error during file upload',
                error: err.message
            });
        }

        // File upload successful, continue to controller
        console.log('File upload successful, proceeding to email controller');
        emailController.sendEmailWithAttachment(req, res);
    });
});

module.exports = router;