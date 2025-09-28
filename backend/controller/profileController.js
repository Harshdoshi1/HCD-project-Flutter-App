const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { Student } = require('../models');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/profiles');
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  // Check if file is an image
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Upload profile image
const uploadProfileImage = async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    // Find student by email
    const student = await Student.findOne({ where: { email } });
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Delete old profile image if exists
    if (student.profileImage) {
      const oldImagePath = path.join(__dirname, '../uploads/profiles', path.basename(student.profileImage));
      if (fs.existsSync(oldImagePath)) {
        fs.unlinkSync(oldImagePath);
      }
    }

    // Generate image URL
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/profiles/${req.file.filename}`;
    
    // Update student record with new profile image URL
    await student.update({ profileImage: imageUrl });

    res.status(200).json({
      message: 'Profile image uploaded successfully',
      imageUrl: imageUrl
    });

  } catch (error) {
    console.error('Error uploading profile image:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get profile image URL
const getProfileImage = async (req, res) => {
  try {
    const { email } = req.params;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Find student by email
    const student = await Student.findOne({ 
      where: { email },
      attributes: ['profileImage']
    });
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    if (!student.profileImage) {
      return res.status(404).json({ error: 'No profile image found' });
    }

    res.status(200).json({
      imageUrl: student.profileImage
    });

  } catch (error) {
    console.error('Error getting profile image:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete profile image
const deleteProfileImage = async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Find student by email
    const student = await Student.findOne({ where: { email } });
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    if (!student.profileImage) {
      return res.status(404).json({ error: 'No profile image found' });
    }

    // Delete image file from filesystem
    const imagePath = path.join(__dirname, '../uploads/profiles', path.basename(student.profileImage));
    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
    }

    // Update student record to remove profile image URL
    await student.update({ profileImage: null });

    res.status(200).json({
      message: 'Profile image deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting profile image:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update profile information
const updateProfile = async (req, res) => {
  try {
    const { email, name, phone, bio } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Find student by email
    const student = await Student.findOne({ where: { email } });
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Prepare update data
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (phone !== undefined) updateData.phone = phone;
    if (bio !== undefined) updateData.bio = bio;

    // Update student record
    await student.update(updateData);

    res.status(200).json({
      message: 'Profile updated successfully',
      student: {
        id: student.id,
        name: student.name,
        email: student.email,
        phone: student.phone,
        bio: student.bio,
        profileImage: student.profileImage
      }
    });

  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Upload profile image from base64 data (web-compatible)
const uploadProfileImageBase64 = async (req, res) => {
  try {
    const { email, imageData, fileName } = req.body;
    
    if (!email || !imageData || !fileName) {
      return res.status(400).json({ error: 'Email, imageData, and fileName are required' });
    }

    // Find student by email
    const student = await Student.findOne({ where: { email } });
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Create uploads directory if it doesn't exist
    const uploadDir = path.join(__dirname, '../uploads/profiles');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    // Delete old profile image if exists
    if (student.profileImage) {
      const oldImagePath = path.join(__dirname, '../uploads/profiles', path.basename(student.profileImage));
      if (fs.existsSync(oldImagePath)) {
        fs.unlinkSync(oldImagePath);
      }
    }

    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const fileExtension = path.extname(fileName) || '.jpg';
    const uniqueFileName = 'profile-' + uniqueSuffix + fileExtension;
    const filePath = path.join(uploadDir, uniqueFileName);

    // Convert base64 to buffer and save file
    const imageBuffer = Buffer.from(imageData, 'base64');
    fs.writeFileSync(filePath, imageBuffer);

    // Generate image URL
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/profiles/${uniqueFileName}`;
    
    // Update student record with new profile image URL
    await student.update({ profileImage: imageUrl });

    res.status(200).json({
      message: 'Profile image uploaded successfully',
      imageUrl: imageUrl
    });

  } catch (error) {
    console.error('Error uploading profile image (base64):', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  upload,
  uploadProfileImage,
  uploadProfileImageBase64,
  getProfileImage,
  deleteProfileImage,
  updateProfile
};
