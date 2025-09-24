const express = require('express');
const router = express.Router();
const multer = require('multer');
const excelUploadController = require('../controller/excelUploadController');
const excelTemplateController = require('../controller/excelTemplateController');

// Configure multer for Excel file uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    },
    fileFilter: (req, file, cb) => {
        if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
            file.mimetype === 'application/vnd.ms-excel') {
            cb(null, true);
        } else {
            cb(new Error('Only Excel files (.xlsx, .xls) are allowed!'), false);
        }
    }
});

// Excel upload routes
router.post('/upload', upload.single('excelFile'), excelUploadController.processExcelUpload);
router.post('/upload-all-classes', upload.single('excelFile'), excelUploadController.processExcelUploadAllClasses);
router.post('/preview', upload.single('excelFile'), excelUploadController.previewExcelData);
router.post('/preview-all-classes', upload.single('excelFile'), excelUploadController.previewExcelDataAllClasses);
router.get('/history/:className/:semesterId/:batchId', excelUploadController.getExcelUploadHistory);

// Excel template routes
router.get('/template', excelTemplateController.generateExcelTemplate);
router.get('/instructions', excelTemplateController.getExcelFormatInstructions);

module.exports = router;
