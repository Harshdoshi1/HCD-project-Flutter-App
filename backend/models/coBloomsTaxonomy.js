// const { DataTypes } = require('sequelize');
// const sequelize = require('../config/db');
// const CourseOutcome = require('./courseOutcome');
// const BloomsTaxonomy = require('./bloomsTaxonomy');

// const CoBloomsTaxonomy = sequelize.define('CoBloomsTaxonomy', {
//     course_outcome_id: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         references: {
//             model: CourseOutcome,
//             key: 'id'
//         }
//     },
//     blooms_taxonomy_id: {
//         type: DataTypes.INTEGER,
//         allowNull: false,
//         references: {
//             model: BloomsTaxonomy,
//             key: 'id'
//         }
//     }
// }, {
//     tableName: 'co_blooms_taxonomy',
//     timestamps: true,
//     updatedAt: 'updated_at',
//     createdAt: 'created_at'
// });

// // Define the composite primary key
// CoBloomsTaxonomy.removeAttribute('id');

// module.exports = CoBloomsTaxonomy; 

const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const CourseOutcome = require('./courseOutcome');
const BloomsTaxonomy = require('./bloomsTaxonomy');

const CoBloomsTaxonomy = sequelize.define(
  'CoBloomsTaxonomy',
  {
    course_outcome_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: CourseOutcome,
        key: 'id',
      },
      primaryKey: true, // 👈 part of composite PK
    },
    blooms_taxonomy_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: BloomsTaxonomy,
        key: 'id',
      },
      primaryKey: true, // 👈 part of composite PK
    },
  },
  {
    tableName: 'co_blooms_taxonomy',
    timestamps: true,
    updatedAt: 'updated_at',
    createdAt: 'created_at',
  }
);

module.exports = CoBloomsTaxonomy;
