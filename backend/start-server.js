require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { syncDB } = require('./models');

const app = express();

// Enable CORS
app.use(cors({
    origin: '*',
    methods: 'GET,POST,PUT,DELETE',
    credentials: true
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test route
app.get('/api/test', (req, res) => {
    res.json({ message: 'Server is running!', timestamp: new Date().toISOString() });
});

// Health check route
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Start Server
const PORT = process.env.PORT || 5001;
const PUBLIC_BASE = process.env.PUBLIC_BASE_URL || process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;

console.log('Starting server...');
console.log('Environment variables:');
console.log('- DB_NAME:', process.env.DB_NAME || 'hcd (default)');
console.log('- DB_USER:', process.env.DB_USER || 'root (default)');
console.log('- DB_HOST:', process.env.DB_HOST || 'localhost (default)');
console.log('- DB_PORT:', process.env.DB_PORT || '3306 (default)');
console.log('- PORT:', PORT);

// Try to start server without database sync first
app.listen(PORT, () => {
    console.log(`✅ Server started successfully on port ${PORT}`);
    console.log(`🌐 Server URL: ${PUBLIC_BASE}`);
    console.log(`🔍 Test endpoint: ${PUBLIC_BASE.replace(/\/$/, '')}/api/test`);
    console.log(`💚 Health check: ${PUBLIC_BASE.replace(/\/$/, '')}/api/health`);

    // Now try to sync database
    console.log('\n🔄 Attempting to sync database...');
    syncDB().then(() => {
        console.log('✅ Database synchronized successfully');
    }).catch(error => {
        console.error('❌ Database sync failed:', error.message);
        console.log('⚠️  Server is running but database is not accessible');
        console.log('💡 Check your database connection and try again');
    });
}).catch(error => {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
});
