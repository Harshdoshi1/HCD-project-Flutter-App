const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const UniqueSubDegree = sequelize.define('UniqueSubDegree', {
    sub_code: { type: DataTypes.STRING, primaryKey: true },
    sub_level: { 
        type: DataTypes.ENUM('department', 'central'), 
        allowNull: false 
    },
    sub_name: { type: DataTypes.STRING, allowNull: false },
    sub_credit: { type: DataTypes.INTEGER, allowNull: false },
    program: { 
        type: DataTypes.ENUM('Degree', 'Diploma'), 
        allowNull: false 
    }
}, { timestamps: false });

module.exports = UniqueSubDegree;
