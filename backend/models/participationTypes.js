const { Sequelize, DataTypes } = require('sequelize');
const sequelize = require('../config/db'); // Adjust the path as per your project structure

const ParticipationType = sequelize.define('ParticipationType', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
    },
    types: {
        type: DataTypes.STRING,
        allowNull: false,
    },
}, {
    tableName: 'participation_types',
    timestamps: false,
});



module.exports = ParticipationType;