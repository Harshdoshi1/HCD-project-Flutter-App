const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Batch = require('./batch');
const Semester = require('./semester');

const StudentCPI = sequelize.define('StudentCPI', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    BatchId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: Batch,
            key: 'id'
        }
    },
    SemesterId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: Semester,
            key: 'id'
        }
    },
    EnrollmentNumber: {
        type: DataTypes.STRING,
        allowNull: false
    },
    CPI: {
        type: DataTypes.FLOAT,
        allowNull: false,
        validate: {
            min: 0,
            max: 10
        }
    },
    SPI: {
        type: DataTypes.FLOAT,
        allowNull: false,
        validate: {
            min: 0,
            max: 10
        }
    },
    Rank: {
        type: DataTypes.INTEGER,
        allowNull: true,
        validate: {
            min: 1
        }
    },
    className: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'Class name when the CPI was recorded'
    }
}, {
    tableName: 'StudentCPIs',
    timestamps: true
});

// Define associations
StudentCPI.belongsTo(Batch, { foreignKey: 'BatchId' });
StudentCPI.belongsTo(Semester, { foreignKey: 'SemesterId' });

module.exports = StudentCPI;