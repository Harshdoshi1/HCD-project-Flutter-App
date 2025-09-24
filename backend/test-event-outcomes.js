const { sequelize, EventOutcomes, EventMaster, EventOutcomeMapping } = require('./models');

async function testEventOutcomes() {
    try {
        console.log('Testing Event Outcomes functionality...');

        // Test 1: Check if EventOutcomes table exists and can be queried
        console.log('\n1. Testing EventOutcomes table...');
        const outcomes = await EventOutcomes.findAll();
        console.log(`Found ${outcomes.length} outcomes:`, outcomes.map(o => ({ id: o.outcome_id, name: o.outcome, type: o.outcome_type })));

        // Test 2: Check if EventMaster table exists
        console.log('\n2. Testing EventMaster table...');
        const events = await EventMaster.findAll();
        console.log(`Found ${events.length} events:`, events.map(e => ({ id: e.eventId, name: e.eventName })));

        // Test 3: Check if EventOutcomeMapping table exists
        console.log('\n3. Testing EventOutcomeMapping table...');
        const mappings = await EventOutcomeMapping.findAll();
        console.log(`Found ${mappings.length} mappings:`, mappings.map(m => ({ id: m.id, eventId: m.eventId, outcomeId: m.outcomeId })));

        // Test 4: Test associations
        console.log('\n4. Testing associations...');
        if (events.length > 0) {
            const eventWithOutcomes = await EventMaster.findByPk(events[0].eventId, {
                include: [{
                    model: EventOutcomes,
                    as: 'outcomes',
                    through: { attributes: [] },
                    attributes: ['outcome_id', 'outcome', 'outcome_type']
                }]
            });
            console.log('Event with outcomes:', eventWithOutcomes ? 'Success' : 'Failed');
        }

        console.log('\n✅ All tests completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await sequelize.close();
    }
}

// Run the test
testEventOutcomes();
