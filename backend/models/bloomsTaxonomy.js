const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const BloomsTaxonomy = sequelize.define('BloomsTaxonomy', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    name: {
        type: DataTypes.STRING(50),
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true
    }
}, {
    tableName: 'blooms_taxonomy',
    timestamps: true,
    updatedAt: 'updated_at',
    createdAt: 'created_at'
});

module.exports = BloomsTaxonomy; 