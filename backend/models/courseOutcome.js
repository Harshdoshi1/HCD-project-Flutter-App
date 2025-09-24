// const { DataTypes } = require('sequelize');
// const sequelize = require('../config/db'); // Assuming your db config is here
// const UniqueSubDegree = require('./uniqueSubDegree'); // Assuming your subject model is named 'subject.js'

// const CourseOutcome = sequelize.define('CourseOutcome', {
//     id: {
//         type: DataTypes.INTEGER,
//         autoIncrement: true,
//         primaryKey: true
//     },
//     subject_id: {
//         type: DataTypes.STRING, // Changed from INTEGER to STRING to match sub_code
//         allowNull: false,
//         references: {
//             model: UniqueSubDegree,
//             key: 'sub_code'
//         }
//     },
//     co_code: { // e.g., "CO1", "CO2"
//         type: DataTypes.STRING(10),
//         allowNull: false
//     },
//     description: {
//         type: DataTypes.TEXT,
//         allowNull: false
//     }
// }, {
//     tableName: 'course_outcomes', // Explicitly set table name
//     timestamps: true, // Sequelize handles createdAt and updatedAt
//     updatedAt: 'updated_at',
//     createdAt: 'created_at',
//     indexes: [
//         {
//             unique: true,
//             fields: ['subject_id', 'co_code']
//         }
//     ]
// });

// module.exports = CourseOutcome;

const { DataTypes } = require('sequelize');
const sequelize = require('../config/db'); 
const UniqueSubDegree = require('./uniqueSubDegree'); 

const CourseOutcome = sequelize.define(
  'CourseOutcome',
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    subject_id: {
      type: DataTypes.STRING, // Matches sub_code in UniqueSubDegree
      allowNull: false,
      references: {
        model: UniqueSubDegree,
        key: 'sub_code',
      },
    },
    co_code: {
      type: DataTypes.STRING(10), // e.g., "CO1", "CO2"
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
  },
  {
    tableName: 'course_outcomes',
    timestamps: true,
    updatedAt: 'updated_at',
    createdAt: 'created_at',
    indexes: [
      {
        unique: true,
        fields: ['subject_id', 'co_code'],
        name: 'uniq_sub_co', // 👈 shorter, avoids duplicate index names
      },
    ],
  }
);

module.exports = CourseOutcome;
