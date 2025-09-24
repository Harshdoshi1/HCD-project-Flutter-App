const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Student = require("./students");
const UniqueSubDegree = require("./uniqueSubDegree");

const SubjectWiseGrade = sequelize.define('SubjectWiseGrade', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    studentId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: Student,
            key: 'id'
        }
    },
    subjectId: {
        type: DataTypes.STRING,
        allowNull: false,
        references: {
            model: UniqueSubDegree,
            key: 'sub_code'
        }
    },
    semester: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    grade: {
        type: DataTypes.ENUM('O', 'A+', 'A', 'B+', 'B', 'C', 'P', 'F'),
        allowNull: false
    },
    points: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    className: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'Class name when the grade was recorded'
    }
}, {
    timestamps: true
});

// Relationships
SubjectWiseGrade.belongsTo(Student, { foreignKey: 'id' });
SubjectWiseGrade.belongsTo(UniqueSubDegree, { foreignKey: 'sub_code' });  // ✅ Clean association

module.exports = SubjectWiseGrade;
