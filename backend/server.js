require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { syncDB } = require('./models');

const userRoutes = require('./routes/auth_routes');
const facultyRoutes = require('./routes/faculty_routes');
const componentRoutes = require('./routes/component_marks_routes');
const studentRoutes = require('./routes/student_routes');
const subRoutes = require('./routes/sub_routes');
// const studentCoCurricularRoutes = require('./routes/student_cocurricular_routes');
// const studentExtracurricularRoutes = require('./routes/student_extracurricular_routes');
const batchRoutes = require("./routes/batch_routes");
const gettedmarksController = require("./controller/gettedmarksController"); 
const students_points_routes = require("./routes/students_points_routes");
const semesterRoutes = require("./routes/semester_routes");
const studentEventRoutes = require("./routes/student_event_routes");
const facultysideRoutes = require("./routes/facultyside_router");
const studentCPIRoutes = require('./routes/studentCPI_routes');
const gradesRoutes = require('./routes/grades_routes');
const academicDetailsRoutes = require('./routes/academic_details_routes');
const bloomsTaxonomyRoutes = require('./routes/bloomsTaxonomyRoutes');
const courseOutcomeRoutes = require('./routes/courseOutcomeRoutes');
const emailRoutes = require('./routes/email_routes');
const mainRouter = require('./routes/index');
const student_event_routes = require('./routes/student_event_routes');
const classSectionRoutes = require('./routes/classSection_routes');
const studentMarksRoutes = require('./routes/studentMarks_routes');
const studentAnalysisRoutes = require('./routes/studentAnalysis_routes');
const bloomsAnalysisRoutes = require('./routes/bloomsAnalysis_routes');
const app = express();

// Enable CORS
app.use(cors({
    origin: '*',
    methods: 'GET,POST,PUT,DELETE',
    credentials: true
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Increase payload size limit for file uploads
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Routes
app.use('/api', mainRouter);
app.use('/api/email', emailRoutes);
app.use('/api/users', userRoutes);
app.use('/api/batches', batchRoutes);
app.use('/api/faculties', facultyRoutes);
app.use('/api/components', componentRoutes);
app.use('/api/students', studentRoutes);
// Using only the events endpoint with proper case
app.use('/api/events', student_event_routes);

// Add a test route to verify the server is working
app.get('/api/test', (req, res) => {
  res.status(200).json({ success: true, message: 'API is working!' });
});
// If students_points_routes is needed, mount it with a different path to avoid conflict
// app.use('/api/students-points', students_points_routes);

// app.use('/api/students/extracurricular', studentExtracurricularRoutes);
// app.use('/api/students/cocurricular', studentCoCurricularRoutes);
app.use('/api/subjects', subRoutes);
app.use('/api/semesters', semesterRoutes);
app.use('/api/class-sections', classSectionRoutes);
// app.use('/api/events', studentEventRoutes); // Commented out to avoid conflict with main events router
app.use('/api/facultyside', facultysideRoutes);
app.use('/api/studentCPI', studentCPIRoutes);
app.use('/api/grades', gradesRoutes);
app.use('/api/academic-details', academicDetailsRoutes);
app.use('/api/blooms-taxonomy', bloomsTaxonomyRoutes);
app.use('/api/course-outcomes', courseOutcomeRoutes);
app.use('/api/student-marks', studentMarksRoutes);
app.use('/api/student-analysis', studentAnalysisRoutes);
app.use('/api/blooms-analysis', bloomsAnalysisRoutes);


app.get("/api/marks/students/:batchId", gettedmarksController.getStudentMarksByBatchAndSubject);
app.get("/api/marks/students/:batchId/:semesterId", gettedmarksController.getStudentsByBatchAndSemester);

app.get("/api/marks/students1/:batchId", gettedmarksController.getStudentMarksByBatchAndSubject1);
app.post("/api/marks/update/:studentId/:subjectId", gettedmarksController.updateStudentMarks);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        message: 'Something went wrong!',
        error: process.env.NODE_ENV === 'development' ? err.message : {}
    });
});

// Catch-all route
app.use((req, res) => {
    res.status(404).json({
        message: 'Route not found'
    });
});

// Start Server
const PORT = process.env.PORT || 5001;

// Synchronize database before starting the server
syncDB().then(() => {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}).catch(error => {
    console.error('Failed to start server:', error);
    process.exit(1);
});
