// const { DataTypes } = require('sequelize');
// const sequelize = require('../config/db');
// const ComponentWeightage = require('./componentWeightage');
// const CourseOutcome = require('./courseOutcome');

// const SubjectComponentCo = sequelize.define('SubjectComponentCo', {
//     id: {
//         type: DataTypes.INTEGER,
//         autoIncrement: true,
//         primaryKey: true
//     },
//     subject_component_id: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         references: {
//             model: ComponentWeightage,
//             key: 'id'
//         }
//     },
//     course_outcome_id: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         references: {
//             model: CourseOutcome,
//             key: 'id'
//         }
//     },
//     component: {
//         type: DataTypes.STRING(10),
//         allowNull: false,
//         comment: 'Component name (e.g., CA, ESE, IA, TW, VIVA)'
//     }
// }, {
//     tableName: 'subject_component_cos',
//     timestamps: true,
//     updatedAt: 'updated_at',
//     createdAt: 'created_at'
// });

// module.exports = SubjectComponentCo;

const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const ComponentWeightage = require('./componentWeightage');
const CourseOutcome = require('./courseOutcome');

const SubjectComponentCo = sequelize.define(
  'SubjectComponentCo',
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    subject_component_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: ComponentWeightage,
        key: 'id',
      },
    },
    course_outcome_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: CourseOutcome,
        key: 'id',
      },
    },
    component: {
      type: DataTypes.STRING(10),
      allowNull: false,
      comment: 'Component name (e.g., CA, ESE, IA, TW, VIVA)',
    },
  },
  {
    tableName: 'subject_component_cos',
    timestamps: true,
    updatedAt: 'updated_at',
    createdAt: 'created_at',

    // 👇 Define shorter explicit unique key
    uniqueKeys: {
      uniq_subcomp_co: {
        fields: ['subject_component_id', 'course_outcome_id'],
      },
    },
  }
);

module.exports = SubjectComponentCo;
