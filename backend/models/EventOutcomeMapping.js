const { DataTypes } = require('sequelize');
const sequelize = require("../config/db");

const EventOutcomeMapping = sequelize.define('EventOutcomeMapping', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        allowNull: false,
    },
    eventId: {
        type: DataTypes.STRING,
        allowNull: false,
        references: {
            model: 'EventMaster',
            key: 'eventId'
        }
    },
    outcomeId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'EventOutcomes',
            key: 'outcome_id'
        }
    }
}, {
    tableName: 'EventOutcomeMapping',
    timestamps: false,
    indexes: [
        {
            unique: true,
            fields: ['eventId', 'outcomeId']
        }
    ]
});

module.exports = EventOutcomeMapping;
