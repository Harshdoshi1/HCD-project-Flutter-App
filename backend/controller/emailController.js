// backend/controller/emailController.js
const nodemailer = require('nodemailer');
require('dotenv').config();

// Create a transporter (using Gmail with specific configuration)
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // Use SSL
    auth: {
        user: process.env.EMAIL_USER || 'krishmamtora26@gmail.com', // Use env variable with fallback
        pass: process.env.EMAIL_PASSWORD // Use an app password from env variables
    },
    tls: {
        // Do not fail on invalid certs
        rejectUnauthorized: false
    },
    debug: true // Enable debug output
});

// Verify transporter configuration
transporter.verify(function(error, success) {
    if (error) {
        console.error('SMTP connection error:', error);
    } else {
        console.log('SMTP server is ready to take our messages');
    }
});

// Send email with PDF attachment
exports.sendEmailWithAttachment = async (req, res) => {
    try {
        console.log('Email request received');
        console.log('Request body:', req.body);
        console.log('Request file:', req.file ? 'File attached' : 'No file attached');

        // Get form data
        const { to, from, subject, text } = req.body;

        // Check if required fields are present
        if (!to) {
            console.error('Missing recipient email address');
            return res.status(400).json({
                success: false,
                message: 'Recipient email address is required'
            });
        }

        // Log environment variables (without exposing passwords)
        console.log('Using EMAIL_USER:', process.env.EMAIL_USER ? 'Set' : 'Not set');
        console.log('Using EMAIL_PASSWORD:', process.env.EMAIL_PASSWORD ? 'Set' : 'Not set');

        // Set up email options
        // const mailOptions = {
        //     from: from || process.env.EMAIL_USER || 'krishmamtora26@gmail.com',
        //     to,
        //     subject: subject || 'Student Performance Report',
        //     text: text || 'Please find attached the student performance report.',
        //     // Add HTML version of the email
        //     html: `
        //         <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 5px;">
        //             <h2 style="color: #4a4a4a; border-bottom: 1px solid #eee; padding-bottom: 10px;">Student Performance Report</h2>
        //             <p style="color: #666; line-height: 1.5;">${text || 'Please find attached the student performance report.'}</p>
        //             <p style="color: #666; line-height: 1.5;">This report contains detailed information about the student's performance across various semesters.</p>
        //             <div style="margin-top: 20px; padding: 15px; background-color: #f9f9f9; border-radius: 4px;">
        //                 <p style="margin: 0; color: #888;">This is an automated email from the Student Performance Dashboard.</p>
        //             </div>
        //         </div>
        //     `,
        //     attachments: []
        // };

        // console.log('Sending email to:', to);
        // console.log('Email subject:', subject);

        // // Check if there's a file attachment
        // if (req.file) {
        //     mailOptions.attachments.push({
        //         filename: 'student-report.pdf',
        //         content: req.file.buffer,
        //         contentType: 'application/pdf'
        //     });
        // }
const mailOptions = {
    from: from || process.env.EMAIL_USER || 'krishmamtora26@gmail.com',
    to,
    subject: subject || 'Student Performance Report',
    text: text || 'Please find attached the student performance report.',
    html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 5px;">
            <h2 style="color: #333; border-bottom: 1px solid #ccc; padding-bottom: 10px;">Student Performance Report</h2>
            <p style="color: #555; line-height: 1.6;">
                ${text || 'Please find attached the student performance report.'}
            </p>
            <p style="color: #555; line-height: 1.6;">
                This report contains detailed information about the student's performance across various semesters.
            </p>
            <div style="margin-top: 20px; padding: 15px; background-color: #f4f4f4; border-radius: 4px;">
                <p style="margin: 0; color: #777;">
                    If you have any questions regarding the report, feel free to contact us.
                </p>
            </div>
        </div>
    `,
    attachments: []
};

// Logging email details
console.log('Sending email to:', to);
console.log('Email subject:', subject);

// Add PDF attachment if provided
if (req.file) {
    mailOptions.attachments.push({
        filename: 'student-report.pdf',
        content: req.file.buffer,
        contentType: 'application/pdf'
    });
}

        // Send the email
        const info = await transporter.sendMail(mailOptions);

        console.log('Email sent successfully:', info.messageId);

        res.status(200).json({
            success: true,
            message: 'Email sent successfully!',
            messageId: info.messageId
        });
    } catch (error) {
        console.error('Error sending email:', error);

        // Log more details about the error
        if (error.code === 'EAUTH') {
            console.error('Authentication error: Check your email credentials');
        } else if (error.code === 'ESOCKET') {
            console.error('Socket error: Check your network connection');
        }

        // Send detailed error response
        res.status(500).json({
            success: false,
            message: 'Failed to send email',
            error: error.message,
            errorCode: error.code || 'UNKNOWN',
            // Don't include stack trace in production
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};