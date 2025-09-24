const { sequelize, EventOutcomes, EventMaster, EventOutcomeMapping } = require('./models');

async function simpleTest() {
    try {
        console.log('Starting simple test...');

        // Test database connection
        await sequelize.authenticate();
        console.log('✅ Database connection successful');

        // Test if tables exist
        const tables = await sequelize.query('SHOW TABLES', { type: sequelize.QueryTypes.SELECT });
        console.log('📋 Available tables:', tables.map(t => Object.values(t)[0]));

        // Test EventOutcomes
        try {
            const outcomes = await EventOutcomes.findAll();
            console.log(`✅ EventOutcomes table accessible, found ${outcomes.length} outcomes`);
            if (outcomes.length > 0) {
                console.log('Sample outcomes:', outcomes.slice(0, 3).map(o => ({ id: o.outcome_id, name: o.outcome, type: o.outcome_type })));
            }
        } catch (error) {
            console.log('❌ EventOutcomes table error:', error.message);
        }

        // Test EventMaster
        try {
            const events = await EventMaster.findAll();
            console.log(`✅ EventMaster table accessible, found ${events.length} events`);
        } catch (error) {
            console.log('❌ EventMaster table error:', error.message);
        }

        // Test EventOutcomeMapping
        try {
            const mappings = await EventOutcomeMapping.findAll();
            console.log(`✅ EventOutcomeMapping table accessible, found ${mappings.length} mappings`);
        } catch (error) {
            console.log('❌ EventOutcomeMapping table error:', error.message);
        }

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await sequelize.close();
        console.log('Database connection closed');
    }
}

simpleTest();
