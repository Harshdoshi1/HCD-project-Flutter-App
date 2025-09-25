// const { DataTypes } = require('sequelize');
// const sequelize = require('../config/db');

// const StudentBloomsDistribution = sequelize.define('StudentBloomsDistribution', {
//     id: {
//         type: DataTypes.INTEGER,
//         primaryKey: true,
//         autoIncrement: true
//     },
//     studentId: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         comment: 'Reference to student ID'
//     },
//     semesterNumber: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         comment: 'Semester number'
//     },
//     batchId: {
//         type: DataTypes.STRING,
//         allowNull: false,
//         comment: 'Batch ID reference'
//     },
//     subjectId: {
//         type: DataTypes.STRING,
//         allowNull: false,
//         comment: 'Subject ID reference'
//     },
//     studentMarksSubjectComponentId: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         comment: 'Reference to StudentMarks.Subject component ID'
//     },
//     totalMarksOfComponent: {
//         type: DataTypes.DECIMAL(5, 2),
//         allowNull: false,
//         defaultValue: 0.00,
//         comment: 'Total marks of the component'
//     },
//     subComponentWeightage: {
//         type: DataTypes.DECIMAL(5, 2),
//         allowNull: false,
//         defaultValue: 0.00,
//         comment: 'SubComponents.weightage value'
//     },
//     selectedCOs: {
//         type: DataTypes.JSON,
//         allowNull: true,
//         comment: 'SubComponents.selectedCOs as JSON array - contains course outcome IDs'
//     },
//     courseOutcomeId: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         comment: 'Reference to course_outcomes.id from selectedCOs array'
//     },
//     bloomsTaxonomyId: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         comment: 'Reference to blooms_taxonomy.id obtained from course_outcomes.blooms_taxonomy_id'
//     },
//     assignedMarks: {
//         type: DataTypes.DECIMAL(5, 2),
//         allowNull: false,
//         defaultValue: 0.00,
//         comment: 'Marks assigned to this specific CO-Blooms taxonomy combination'
//     },
//     calculatedAt: {
//         type: DataTypes.DATE,
//         allowNull: false,
//         defaultValue: DataTypes.NOW,
//         comment: 'Timestamp when calculation was performed'
//     }
// }, {
//     tableName: 'student_blooms_distribution',
//     timestamps: true,
//     indexes: [
//         {
//             unique: true,
//             name: 'idx_student_component_co_blooms',
//             fields: ['studentId', 'studentMarksSubjectComponentId', 'courseOutcomeId', 'bloomsTaxonomyId']
//         },
//         {
//             name: 'idx_student_semester_batch',
//             fields: ['studentId', 'semesterNumber', 'batchId']
//         },
//         {
//             name: 'idx_subject_semester_batch',
//             fields: ['subjectId', 'semesterNumber', 'batchId']
//         },
//         {
//             name: 'idx_component_reference',
//             fields: ['studentMarksSubjectComponentId']
//         },
//         {
//             name: 'idx_course_outcome_blooms',
//             fields: ['courseOutcomeId', 'bloomsTaxonomyId']
//         }
//     ]
// });

// module.exports = StudentBloomsDistribution;
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const StudentBloomsDistribution = sequelize.define('StudentBloomsDistribution', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    studentId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Reference to student ID'
    },
    semesterNumber: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Semester number'
    },
    subjectId: {
        type: DataTypes.STRING,
        allowNull: false,
        comment: 'Subject ID reference'
    },
    studentMarksSubjectComponentId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Reference to StudentMarks.Subject component ID'
    },
    totalMarksOfComponent: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'Total marks of the component'
    },
    subComponentWeightage: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'SubComponents.weightage value'
    },
    selectedCOs: {
        type: DataTypes.JSON,
        allowNull: true,
        comment: 'SubComponents.selectedCOs as JSON array - contains course outcome IDs'
    },
    courseOutcomeId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Reference to course_outcomes.id from selectedCOs array'
    },
    bloomsTaxonomyId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Reference to blooms_taxonomy.id obtained from course_outcomes.blooms_taxonomy_id'
    },
    assignedMarks: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'Marks assigned to this specific CO-Blooms taxonomy combination'
    },
    calculatedAt: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
        comment: 'Timestamp when calculation was performed'
    }
}, {
    tableName: 'student_blooms_distribution',
    timestamps: true,
    indexes: [
        {
            name: 'idx_student_component_co_blooms',
            fields: ['studentId', 'studentMarksSubjectComponentId', 'courseOutcomeId', 'bloomsTaxonomyId']
        },
        {
            name: 'idx_student_semester',
            fields: ['studentId', 'semesterNumber']
        },
        {
            name: 'idx_subject_semester',
            fields: ['subjectId', 'semesterNumber']
        },
        {
            name: 'idx_component_reference',
            fields: ['studentMarksSubjectComponentId']
        },
        {
            name: 'idx_course_outcome_blooms',
            fields: ['courseOutcomeId', 'bloomsTaxonomyId']
        }
    ]
});

module.exports = StudentBloomsDistribution;
