const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const EventOutcomes = sequelize.define('EventOutcomes', {
    outcome_id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    outcome: {
        type: DataTypes.STRING,
        allowNull: false
    },
    outcome_type: {
        type: DataTypes.ENUM('Technical', 'Non-Technical'),
        allowNull: false
    },
}, { timestamps: false });

module.exports = EventOutcomes;
