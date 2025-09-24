const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const UniqueSubDiploma = sequelize.define('UniqueSubDiploma', {
    sub_code: { type: DataTypes.STRING, primaryKey: true },
    sub_level: { 
        type: DataTypes.ENUM('department', 'central'), 
        allowNull: false 
    },
    sub_name: { type: DataTypes.STRING, allowNull: false },
    sub_credit: { type: DataTypes.INTEGER, allowNull: false }
}, { timestamps: false });

module.exports = UniqueSubDiploma;
