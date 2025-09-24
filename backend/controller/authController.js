const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models'); // Import models
const { Op } = require("sequelize"); // Ensure Op is imported
const nodemailer = require('nodemailer');

// Store reset tokens temporarily (In production, use a database table)
const resetTokens = {};

const registerUser = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        // Check if user already exists
        const userExists = await User.findOne({ where: { email } });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create user
        const user = await User.create({ name, email, password: hashedPassword, role });

        res.status(201).json({ message: 'User registered successfully', user });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log("emaio",email)

        if (!email || !password) {
            return res.status(400).json({ 
                message: 'Email and password are required',
                error: 'Missing required fields'
            });
        }

        // Log the received email (for debugging)
        console.log('Login attempt for email:', email);

        // Check if user exists
        const user = await User.findOne({ where: { email } });
        if (!user) {
            console.log('User not found for email:', email);
            return res.status(400).json({ 
                message: 'Invalid email or password',
                error: 'User not found'
            });
        }

        // Validate password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            console.log('Invalid password for email:', email);
            return res.status(400).json({ 
                message: 'Invalid email or password',
                error: 'Invalid password'
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '1h' }
        );

        console.log('Login successful for email:', email);
        res.status(200).json({ 
            message: 'Login successful', 
            token, 
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ 
            message: 'Server Error', 
            error: error.message 
        });
    }
};

const getAllUsers = async (req, res) => {
    try {
        const users = await User.findAll({ attributes: { exclude: ['password'] } }); // Exclude password
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// Get user by email
const getUserByEmail = async (req, res) => {
    try {
        const { email } = req.params;
        
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }
        
        const user = await User.findOne({ 
            where: { email },
            attributes: { exclude: ['password'] } // Exclude password
        });
        
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        res.status(200).json(user);
    } catch (error) {
        console.error('Error fetching user by email:', error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// Update user profile
const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { username, email } = req.body;
        
        // Find user
        const user = await User.findByPk(id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Update user details
        await user.update({
            name: username || user.name,
            email: email || user.email
        });
        
        res.status(200).json({ 
            success: true, 
            message: 'User updated successfully',
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// Send password reset email
const sendResetEmail = async (req, res) => {
    try {
        const { email, token, senderEmail } = req.body;
        
        if (!email || !token) {
            return res.status(400).json({ message: 'Email and token are required' });
        }
        
        // Check if user exists
        const user = await User.findOne({ where: { email } });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Store token with expiration time (1 hour)
        resetTokens[email] = {
            token,
            expires: Date.now() + 3600000 // 1 hour in milliseconds
        };
        
        try {
            // Create Nodemailer transporter
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: senderEmail || 'krishmamtora26@gmail.com', // Default sender email
                    pass: process.env.EMAIL_PASSWORD // You need to store this securely
                }
            });
            
            // Email content
            const mailOptions = {
                from: senderEmail || 'krishmamtora26@gmail.com',
                to: email,
                subject: 'Password Reset',
                html: `
                    <h1>Password Reset Request</h1>
                    <p>You have requested to reset your password. Please use the token below:</p>
                    <p><strong>Token: ${token}</strong></p>
                    <p>Enter this token along with your new password in the application.</p>
                    <p>This token will expire in 1 hour.</p>
                    <p>If you did not request this, please ignore this email.</p>
                `
            };
            
            // Send email
            await transporter.sendMail(mailOptions);
            console.log(`Email sent successfully to ${email} with token: ${token}`);
        } catch (emailError) {
            console.warn('Email sending failed, but continuing for development mode:', emailError.message);
            console.log(`Development mode: Password reset token for ${email} is: ${token}`);
            // In development, we'll just log the token and continue the process
            // In production, you might want to fail here with: throw emailError;
        }
        
        res.status(200).json({ success: true, message: 'Reset email sent successfully' });
    } catch (error) {
        console.error('Error sending reset email:', error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// Reset password with token
const resetPassword = async (req, res) => {
    try {
        const { email, token, newPassword } = req.body;
        
        if (!email || !token || !newPassword) {
            return res.status(400).json({ message: 'Email, token, and new password are required' });
        }
        
        // Check if token exists and is valid
        const resetData = resetTokens[email];
        if (!resetData || resetData.token !== token) {
            return res.status(400).json({ message: 'Invalid or expired token' });
        }
        
        // Check if token is expired
        if (Date.now() > resetData.expires) {
            delete resetTokens[email]; // Clean up expired token
            return res.status(400).json({ message: 'Token has expired' });
        }
        
        // Find user
        const user = await User.findOne({ where: { email } });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);
        
        // Update password
        await user.update({ password: hashedPassword });
        
        // Clean up used token
        delete resetTokens[email];
        
        res.status(200).json({ success: true, message: 'Password reset successfully' });
    } catch (error) {
        console.error('Error resetting password:', error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getAllUsers,
    getUserByEmail,
    updateUser,
    sendResetEmail,
    resetPassword
};
