const express = require('express');
const router = express.Router();
const { 
  upload, 
  uploadProfileImage, 
  uploadProfileImageBase64,
  getProfileImage, 
  deleteProfileImage, 
  updateProfile 
} = require('../controller/profileController');
const authenticateToken = require('../middleware/authenticateToken');

// Upload profile image (multipart)
router.post('/uploadImage', authenticateToken, upload.single('profileImage'), uploadProfileImage);

// Upload profile image (base64 - web compatible)
router.post('/uploadImageBase64', authenticateToken, uploadProfileImageBase64);

// Get profile image URL
router.get('/getImage/:email', authenticateToken, getProfileImage);

// Delete profile image
router.delete('/deleteImage', authenticateToken, deleteProfileImage);

// Update profile information
router.put('/update', authenticateToken, updateProfile);

module.exports = router;
