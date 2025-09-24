const sequelize = require('../config/db');

/**
 * Clean up orphaned records and fix foreign key constraint issues
 */
const cleanupDatabase = async () => {
    try {
        console.log('Starting database cleanup...');

        // Disable foreign key checks
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');

        // Clean up StudentCPIs table
        console.log('Cleaning StudentCPIs table...');

        // Remove records with invalid SemesterId
        const deletedSemesters = await sequelize.query(`
            DELETE sc FROM StudentCPIs sc 
            LEFT JOIN Semesters s ON sc.SemesterId = s.id 
            WHERE s.id IS NULL
        `);
        console.log(`Removed ${deletedSemesters[0].affectedRows || 0} StudentCPI records with invalid SemesterId`);

        // Remove records with invalid BatchId
        const deletedBatches = await sequelize.query(`
            DELETE sc FROM StudentCPIs sc 
            LEFT JOIN Batches b ON sc.BatchId = b.id 
            WHERE b.id IS NULL
        `);
        console.log(`Removed ${deletedBatches[0].affectedRows || 0} StudentCPI records with invalid BatchId`);

        // Clean up StudentMarks table
        console.log('Cleaning StudentMarks table...');

        // Remove records with invalid studentId
        const deletedStudentMarks = await sequelize.query(`
            DELETE sm FROM StudentMarks sm 
            LEFT JOIN Students s ON sm.studentId = s.id 
            WHERE s.id IS NULL
        `);
        console.log(`Removed ${deletedStudentMarks[0].affectedRows || 0} StudentMarks records with invalid studentId`);

        // Clean up StudentBloomsDistribution table
        console.log('Cleaning StudentBloomsDistribution table...');

        // Remove records with invalid studentId
        const deletedBloomsStudent = await sequelize.query(`
            DELETE sbd FROM student_blooms_distribution sbd 
            LEFT JOIN Students s ON sbd.studentId = s.id 
            WHERE s.id IS NULL
        `);
        console.log(`Removed ${deletedBloomsStudent[0].affectedRows || 0} StudentBloomsDistribution records with invalid studentId`);

        // Remove records with invalid courseOutcomeId
        const deletedBloomsCO = await sequelize.query(`
            DELETE sbd FROM student_blooms_distribution sbd 
            LEFT JOIN course_outcomes co ON sbd.courseOutcomeId = co.id 
            WHERE co.id IS NULL
        `);
        console.log(`Removed ${deletedBloomsCO[0].affectedRows || 0} StudentBloomsDistribution records with invalid courseOutcomeId`);

        // Remove records with invalid bloomsTaxonomyId
        const deletedBloomsTaxonomy = await sequelize.query(`
            DELETE sbd FROM student_blooms_distribution sbd 
            LEFT JOIN blooms_taxonomy bt ON sbd.bloomsTaxonomyId = bt.id 
            WHERE bt.id IS NULL
        `);
        console.log(`Removed ${deletedBloomsTaxonomy[0].affectedRows || 0} StudentBloomsDistribution records with invalid bloomsTaxonomyId`);

        // Re-enable foreign key checks
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');

        console.log('Database cleanup completed successfully.');

    } catch (error) {
        console.error('Error during database cleanup:', error);

        // Make sure to re-enable foreign key checks even if cleanup fails
        try {
            await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
        } catch (fkError) {
            console.error('Failed to re-enable foreign key checks:', fkError);
        }

        throw error;
    }
};

/**
 * Check database integrity
 */
const checkDatabaseIntegrity = async () => {
    try {
        console.log('Checking database integrity...');

        // Check for orphaned StudentCPI records
        const orphanedCPIs = await sequelize.query(`
            SELECT COUNT(*) as count FROM StudentCPIs sc 
            LEFT JOIN Semesters s ON sc.SemesterId = s.id 
            LEFT JOIN Batches b ON sc.BatchId = b.id 
            WHERE s.id IS NULL OR b.id IS NULL
        `, { type: sequelize.QueryTypes.SELECT });

        if (orphanedCPIs[0].count > 0) {
            console.warn(`Found ${orphanedCPIs[0].count} orphaned StudentCPI records`);
        }

        // Check for orphaned StudentMarks records
        const orphanedMarks = await sequelize.query(`
            SELECT COUNT(*) as count FROM StudentMarks sm 
            LEFT JOIN Students s ON sm.studentId = s.id 
            WHERE s.id IS NULL
        `, { type: sequelize.QueryTypes.SELECT });

        if (orphanedMarks[0].count > 0) {
            console.warn(`Found ${orphanedMarks[0].count} orphaned StudentMarks records`);
        }

        console.log('Database integrity check completed.');

    } catch (error) {
        console.error('Error during integrity check:', error);
    }
};

module.exports = {
    cleanupDatabase,
    checkDatabaseIntegrity
};
