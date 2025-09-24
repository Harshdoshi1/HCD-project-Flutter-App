const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const UniqueSubDegree = require("./uniqueSubDegree"); 

const ComponentMarks = sequelize.define(
  "ComponentMarks",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    subjectId: {
      type: DataTypes.STRING, // Change to match UniqueSubDegree.sub_code
      allowNull: false,
      references: {
        model: UniqueSubDegree, 
        key: "sub_code",
      },
    },
    ese: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    cse: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    ia: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    tw: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    viva: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
  },
  { timestamps: false }
);

// Associations

ComponentMarks.belongsTo(UniqueSubDegree, { foreignKey: "subjectId", targetKey: "sub_code" });

module.exports = ComponentMarks;
