const sequelize = require('../config/db');
const User = require('./users');
const Batch = require('./batch');
const Semester = require('./semester');
const Faculty = require('./faculty');
const Subject = require('./subjects');
const UniqueSubDegree = require('./uniqueSubDegree');
const UniqueSubDiploma = require('./uniqueSubDiploma');
const AssignSubject = require('./assignSubject');
const ComponentWeightage = require('./componentWeightage');
const ComponentMarks = require('./componentMarks');
const Student = require('./students');
const StudentCPI = require('./studentCPI');
const Gettedmarks = require('./gettedmarks');
const SubjectWiseGrades = require('./SubjectWiseGrades');
const ParticipationType = require('./participationTypes');
const CourseOutcome = require('./courseOutcome');
const SubjectComponentCo = require('./subjectComponentCo');
const ClassSection = require('./classSection');
const EventOutcomes = require('./EventOutcomes');
const EventOutcomeMapping = require('./EventOutcomeMapping');
const SubComponents = require('./subComponents');
const StudentMarks = require('./studentMarks');
const StudentBloomsDistribution = require('./StudentBloomsDistribution');
const BloomsTaxonomy = require('./bloomsTaxonomy');
const CoBloomsTaxonomy = require('./coBloomsTaxonomy');
const StudentPoints = require('./StudentPoints');
const EventMaster = require('./EventMaster');
// const User = require('./users');   


// Import associations to set up relationships
require('./associations');

// const CoCurricularActivity = require('./cocurricularActivity');
// const ExtraCurricularActivity = require('./extraCurricularActivity');
// const CoCurricularActivities = require('./coCurricularActivity');

const syncDB = async () => {
    try {
        console.log('Starting database synchronization...');

        // First check if tables exist
        const tables = await sequelize.query('SHOW TABLES', { type: sequelize.QueryTypes.SELECT });
        const tableNames = tables.map(table => Object.values(table)[0]);

        // If no tables exist, create them
        if (tableNames.length === 0) {
            console.log('No tables found. Creating all tables...');
            await sequelize.sync({ force: true });
        } else {
            // If tables exist, handle foreign key constraints carefully
            console.log('Tables found. Synchronizing with safer approach...');

            try {
                // Disable foreign key checks temporarily
                await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');

                // Clean up orphaned records in StudentCPIs table
                console.log('Cleaning up orphaned records...');

                // Remove StudentCPI records that reference non-existent semesters
                await sequelize.query(`
                    DELETE sc FROM StudentCPIs sc 
                    LEFT JOIN Semesters s ON sc.SemesterId = s.id 
                    WHERE s.id IS NULL
                `);

                // Remove StudentCPI records that reference non-existent batches
                await sequelize.query(`
                    DELETE sc FROM StudentCPIs sc 
                    LEFT JOIN Batches b ON sc.BatchId = b.id 
                    WHERE b.id IS NULL
                `);

                // Re-enable foreign key checks
                await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');

                // Now sync with alter option
                await sequelize.sync({ alter: true });

            } catch (syncError) {
                // If sync still fails, try without foreign key constraints
                console.warn('Sync with alter failed, trying without constraints...');
                await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');
                await sequelize.sync({ alter: true });
                await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
            }
        }

        console.log('Database synchronization completed successfully.');
    } catch (error) {
        console.error('Error during database synchronization:', error);

        // As a last resort, try to continue without strict sync
        try {
            console.log('Attempting to start server without strict synchronization...');
            await sequelize.authenticate();
            console.log('Database connection verified. Server will start with existing schema.');
        } catch (authError) {
            console.error('Database authentication failed:', authError);
            throw error;
        }
    }
};

module.exports = {
    sequelize,
    Batch,
    Semester,
    Faculty,
    Subject,
    UniqueSubDegree,
    UniqueSubDiploma,
    AssignSubject,
    ComponentWeightage,
    ComponentMarks,
    Student,
    StudentCPI,
    Gettedmarks,
    SubjectWiseGrades,
    ParticipationType,
    CourseOutcome,
    SubjectComponentCo,
    ClassSection,
    EventOutcomes,
    EventOutcomeMapping,
    SubComponents,
    StudentMarks,
    StudentBloomsDistribution,
    BloomsTaxonomy,
    CoBloomsTaxonomy,
    StudentPoints,
    EventMaster,
    User,
    syncDB
};
