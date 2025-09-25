const { sequelize } = require('./models');

const syncDatabase = async () => {
  try {
    console.log('Starting database synchronization...');
    
    // Sync all models
    await sequelize.sync({ alter: true });
    
    console.log('Database synchronized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error synchronizing database:', error);
    process.exit(1);
  }
};

syncDatabase();