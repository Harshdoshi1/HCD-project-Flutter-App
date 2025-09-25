const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const ComponentWeightage = require("./componentWeightage");

const SubComponents = sequelize.define(
  "SubComponents",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    componentWeightageId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: ComponentWeightage,
        key: "id",
      },
    },
    componentType: {
      type: DataTypes.ENUM('CA', 'ESE', 'IA', 'TW', 'VIVA'),
      allowNull: false,
    },
    subComponentName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    weightage: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    totalMarks: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    selectedCOs: {
      type: DataTypes.JSON, // Store array of CO IDs
      allowNull: true,
      defaultValue: [],
    },
    isEnabled: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
  },
  { 
    timestamps: true,
    tableName: 'SubComponents'
  }
);

// Associations are defined in associations.js to avoid conflicts

module.exports = SubComponents;
