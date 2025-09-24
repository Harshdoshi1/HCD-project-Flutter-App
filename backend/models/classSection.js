const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Semester = require('./semester');
const Batch = require('./batch');

const ClassSection = sequelize.define('ClassSection', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    semesterId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Semester, key: 'id' }
    },
    batchId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Batch, key: 'id' }
    },
    className: {
        type: DataTypes.STRING,
        allowNull: false
    },
    classLetter: {
        type: DataTypes.STRING(1),
        allowNull: false
    },
    studentCount: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0
    },
    excelFileName: {
        type: DataTypes.STRING,
        allowNull: true
    },
    isActive: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true
    }
}, {
    timestamps: false,
    tableName: 'ClassSections'
});

module.exports = ClassSection; 