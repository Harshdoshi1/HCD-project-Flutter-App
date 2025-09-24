const express = require('express');
const {
    registerUser,
    loginUser,
    getAllUsers,
    getUserByEmail,
    updateUser,
    sendResetEmail,
    resetPassword
} = require('../controller/authController'); // Ensure correct path

const router = express.Router();

// User Routes
router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/getAllUsers', getAllUsers);

// Profile management routes
router.get('/users/byEmail/:email', getUserByEmail);
router.put('/users/:id', updateUser);

// Password reset routes
router.post('/send-reset-email', sendResetEmail);
router.post('/reset-password', resetPassword);

module.exports = router;
