// const { DataTypes } = require("sequelize");
// const sequelize = require("../config/db");
// const UniqueSubDegree = require("./uniqueSubDegree"); 
// const User = require("./users");
// const Student = require("./students");

// const Gettedmarks = sequelize.define(
//   "Gettedmarks",
//   {
//     id: {
//       type: DataTypes.INTEGER,
//       autoIncrement: true,
//       primaryKey: true,
//     },
//     studentId: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       references: {
//         model: Student,
//         key: "id",
//       },
//     },
//     facultyId: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       references: { 
//         model: User, 
//         key: 'id', 
//       },
//     },
//     subjectId: {
//       type: DataTypes.STRING, // Change to match UniqueSubDegree.sub_code
//       allowNull: false,
//       references: {
//         model: UniqueSubDegree, 
//         key: "sub_code",
//       },
//     },
//     ese: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       defaultValue: 0,
//     },
//     cse: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       defaultValue: 0,
//     },
//     ia: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       defaultValue: 0,
//     },
//     tw: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       defaultValue: 0,
//     },
//     viva: {
//       type: DataTypes.INTEGER,
//       allowNull: false,
//       defaultValue: 0,
//     },
//   },
//   { timestamps: false }
// );

// // Associations

// Gettedmarks.belongsTo(UniqueSubDegree, { foreignKey: "subjectId", targetKey: "sub_code" });
// Gettedmarks.belongsTo(User, { foreignKey: 'facultyId' });
// module.exports = Gettedmarks;


const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const UniqueSubDegree = require("./uniqueSubDegree"); 
const User = require("./users");
const Student = require("./students");

const Gettedmarks = sequelize.define(
  "Gettedmarks",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    studentId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Student,
        key: "id",
      },
    },
    facultyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { 
        model: User, 
        key: 'id', 
      },
    },
    subjectId: {
      type: DataTypes.STRING, // Change to match UniqueSubDegree.sub_code
      allowNull: false,
      references: {
        model: UniqueSubDegree, 
        key: "sub_code",
      },
    },
    ese: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
    },
    cse: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
    },
    ia: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
    },
    tw: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
    },
    viva: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
    },
    facultyResponse: {
      type: DataTypes.STRING,
      allowNull: true, // Can be null if not provided
    },
    facultyRating: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0,
        max: 10,
      },
    },
    grades: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  },
  { timestamps: false }
);

// Associations
Gettedmarks.belongsTo(UniqueSubDegree, { foreignKey: "subjectId", targetKey: "sub_code" });
Gettedmarks.belongsTo(User, { foreignKey: 'facultyId' });

module.exports = Gettedmarks;
