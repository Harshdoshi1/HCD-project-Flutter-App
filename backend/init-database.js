const { sequelize, EventOutcomes, EventMaster, EventOutcomeMapping } = require('./models');

async function initDatabase() {
    try {
        console.log('Initializing database...');

        // Sync database
        await sequelize.sync({ alter: true });
        console.log('✅ Database synced');

        // Check if outcomes already exist
        const existingOutcomes = await EventOutcomes.findAll();

        if (existingOutcomes.length === 0) {
            console.log('Creating sample event outcomes...');

            // Create technical outcomes
            const technicalOutcomes = [
                'Problem Solving',
                'Critical Thinking',
                'Analytical Skills',
                'Programming Skills',
                'Data Analysis',
                'System Design',
                'Algorithm Design',
                'Database Management',
                'Network Security',
                'Software Testing'
            ];

            // Create non-technical outcomes
            const nonTechnicalOutcomes = [
                'Leadership',
                'Teamwork',
                'Communication',
                'Time Management',
                'Creativity',
                'Adaptability',
                'Presentation Skills',
                'Project Management',
                'Problem Analysis',
                'Innovation'
            ];

            // Insert technical outcomes
            for (const outcome of technicalOutcomes) {
                await EventOutcomes.create({
                    outcome: outcome,
                    outcome_type: 'Technical'
                });
            }

            // Insert non-technical outcomes
            for (const outcome of nonTechnicalOutcomes) {
                await EventOutcomes.create({
                    outcome: outcome,
                    outcome_type: 'Non-Technical'
                });
            }

            console.log('✅ Sample outcomes created');
        } else {
            console.log(`✅ ${existingOutcomes.length} outcomes already exist`);
        }

        // Display all outcomes
        const allOutcomes = await EventOutcomes.findAll();
        console.log('\n📋 All outcomes:');
        allOutcomes.forEach(outcome => {
            console.log(`  - ${outcome.outcome} (${outcome.outcome_type})`);
        });

    } catch (error) {
        console.error('❌ Initialization failed:', error);
    } finally {
        await sequelize.close();
        console.log('Database connection closed');
    }
}

initDatabase();
