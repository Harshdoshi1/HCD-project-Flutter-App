const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./users');

const Faculty = sequelize.define('Faculty', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: { type: DataTypes.INTEGER, unique: true, allowNull: false, references: { model: User, key: 'id' } }
}, { timestamps: true });

Faculty.belongsTo(User, { foreignKey: 'userId' });

module.exports = Faculty;
