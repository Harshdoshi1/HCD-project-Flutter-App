const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bloomsTaxonomyRoutes = require('./routes/bloomsTaxonomyRoutes');
const subRoutes = require('./routes/subRoutes');
const courseOutcomeRoutes = require('./routes/courseOutcomeRoutes');
const subjectComponentCoRoutes = require('./routes/subjectComponentCoRoutes');
const eventsRoutes = require('./routes/events');
const studentEventRoutes = require('./routes/student_event_routes');
const eventOutcomesRoutes = require('./routes/eventOutcomeRoutes');
const studentAnalysisRoutes = require('./routes/studentAnalysis_routes');
const bloomsDistributionRoutes = require('./routes/bloomsDistribution_routes');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api/blooms-taxonomy', bloomsTaxonomyRoutes);
app.use('/api/subjects', subRoutes);
app.use('/api/course-outcomes', courseOutcomeRoutes);
app.use('/api/subject-component-cos', subjectComponentCoRoutes);
// app.use('/api', eventsRoutes);
app.use('/api/events', studentEventRoutes);
// app.use('/api', eventOutcomesRoutes);
app.use('/api/student-analysis', studentAnalysisRoutes);
app.use('/api/blooms-distribution', bloomsDistributionRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ message: 'Route not found' });
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

module.exports = app; 