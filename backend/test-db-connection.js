require('dotenv').config();
const sequelize = require('./config/db');

async function testDatabaseConnection() {
    console.log('🔍 Testing database connection...\n');

    console.log('Environment variables:');
    console.log('- DB_NAME:', process.env.DB_NAME || 'hcd (default)');
    console.log('- DB_USER:', process.env.DB_USER || 'root (default)');
    console.log('- DB_HOST:', process.env.DB_HOST || 'localhost (default)');
    console.log('- DB_PORT:', process.env.DB_PORT || '3306 (default)');
    console.log('');

    try {
        // Test basic connection
        console.log('1. Testing basic connection...');
        await sequelize.authenticate();
        console.log('   ✅ Database connection successful');

        // Test if we can query
        console.log('\n2. Testing query capability...');
        const result = await sequelize.query('SELECT 1 as test');
        console.log('   ✅ Query test successful:', result[0]);

        // Test if database exists
        console.log('\n3. Testing database existence...');
        const databases = await sequelize.query('SHOW DATABASES');
        const dbNames = databases[0].map(db => db.Database);
        console.log('   ✅ Available databases:', dbNames);

        if (dbNames.includes(process.env.DB_NAME || 'hcd')) {
            console.log('   ✅ Target database exists');
        } else {
            console.log('   ⚠️  Target database does not exist');
            console.log('   💡 You may need to create the database first');
        }

        console.log('\n🎉 Database connection test completed successfully!');

    } catch (error) {
        console.error('\n❌ Database connection test failed:');
        console.error('Error:', error.message);

        if (error.code === 'ECONNREFUSED') {
            console.log('\n💡 Solution: MySQL server is not running');
            console.log('   - Start MySQL service');
            console.log('   - Check if MySQL is running on port 3306');
        } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
            console.log('\n💡 Solution: Database credentials are incorrect');
            console.log('   - Check DB_USER and DB_PASSWORD in .env file');
            console.log('   - Verify user has access to the database');
        } else if (error.code === 'ENOTFOUND') {
            console.log('\n💡 Solution: Database host not found');
            console.log('   - Check DB_HOST in .env file');
            console.log('   - Verify MySQL is running on the specified host');
        } else if (error.code === 'ER_BAD_DB_ERROR') {
            console.log('\n💡 Solution: Database does not exist');
            console.log('   - Create the database first');
            console.log('   - Check DB_NAME in .env file');
        }

    } finally {
        await sequelize.close();
        console.log('\n🔌 Database connection closed');
    }
}

// Run the test
testDatabaseConnection();
