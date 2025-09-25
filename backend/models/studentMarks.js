const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const UniqueSubDegree = require("./uniqueSubDegree");
const User = require("./users");
const Student = require("./students");
const Semester = require("./semester");
const Batch = require("./batch");
const SubComponents = require("./subComponents");

const StudentMarks = sequelize.define(
  "StudentMarks",
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
        key: "id",
      },
    },
    subjectId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: UniqueSubDegree,
        key: "sub_code",
      },
    },
    semesterId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Semester,
        key: "id",
      },
    },
    batchId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Batch,
        key: "id",
      },
    },
    subComponentId: {
      type: DataTypes.INTEGER,
      allowNull: true, // Null for main components, filled for sub-components
      references: {
        model: SubComponents,
        key: "id",
      },
    },
    componentType: {
      type: DataTypes.ENUM('CA', 'ESE', 'IA', 'TW', 'VIVA'),
      allowNull: false,
    },
    componentName: {
      type: DataTypes.STRING,
      allowNull: true, // For sub-component names
    },
    marksObtained: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: false,
      defaultValue: 0,
    },
    totalMarks: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    facultyResponse: {
      type: DataTypes.TEXT,
      allowNull: true,
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
      allowNull: true,
    },
    isSubComponent: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    enrollmentSemester: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: "Semester in which student enrolled for this subject",
    },
  },
  { 
    timestamps: true,
    tableName: 'StudentMarks'
  }
);

// Associations are defined in associations.js to avoid conflicts

module.exports = StudentMarks;
