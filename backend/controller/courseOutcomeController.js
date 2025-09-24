const CourseOutcome = require('../models/courseOutcome');
const UniqueSubDegree = require('../models/uniqueSubDegree');

// Get all course outcomes for a specific subject
exports.getCourseOutcomesBySubject = async (req, res) => {
    try {
        const { subjectId } = req.params;
        
        // Check if subject exists
        const subjectExists = await UniqueSubDegree.findOne({ 
            where: { sub_code: subjectId }
        });
        
        if (!subjectExists) {
            return res.status(404).json({ 
                message: 'Subject not found',
                subjectId: subjectId
            });
        }

        const courseOutcomes = await CourseOutcome.findAll({
            where: { subject_id: subjectId },
            order: [['co_code', 'ASC']]
        });

        res.status(200).json(courseOutcomes);
    } catch (error) {
        console.error('Error fetching course outcomes:', error);
        res.status(500).json({ 
            error: error.message,
            type: error.name,
            details: error.errors?.map(e => e.message) || []
        });
    }
};

// Get a specific course outcome by ID
exports.getCourseOutcomeById = async (req, res) => {
    try {
        const { id } = req.params;
        const courseOutcome = await CourseOutcome.findByPk(id);
        
        if (!courseOutcome) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }
        
        res.status(200).json(courseOutcome);
    } catch (error) {
        console.error('Error fetching course outcome:', error);
        res.status(500).json({ error: error.message });
    }
};

// Create a new course outcome
exports.createCourseOutcome = async (req, res) => {
    try {
        const { subject_id, co_code, description } = req.body;

        // Validate required fields
        if (!subject_id || !co_code || !description) {
            return res.status(400).json({ 
                error: 'Missing required fields',
                required: ['subject_id', 'co_code', 'description']
            });
        }

        // Check if subject exists
        const subjectExists = await UniqueSubDegree.findOne({ 
            where: { sub_code: subject_id }
        });
        
        if (!subjectExists) {
            return res.status(404).json({ 
                message: 'Subject not found',
                subjectId: subject_id
            });
        }

        // Check if CO code already exists for this subject
        const existingCO = await CourseOutcome.findOne({
            where: {
                subject_id: subject_id,
                co_code: co_code
            }
        });

        if (existingCO) {
            return res.status(400).json({ 
                message: 'Course Outcome code already exists for this subject',
                co_code: co_code
            });
        }

        const courseOutcome = await CourseOutcome.create({
            subject_id,
            co_code,
            description
        });

        res.status(201).json(courseOutcome);
    } catch (error) {
        console.error('Error creating course outcome:', error);
        res.status(500).json({ error: error.message });
    }
};

// Update a course outcome
exports.updateCourseOutcome = async (req, res) => {
    try {
        const { id } = req.params;
        const { description } = req.body;

        const courseOutcome = await CourseOutcome.findByPk(id);
        
        if (!courseOutcome) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }

        await courseOutcome.update({ description });
        
        res.status(200).json(courseOutcome);
    } catch (error) {
        console.error('Error updating course outcome:', error);
        res.status(500).json({ error: error.message });
    }
};

// Delete a course outcome
exports.deleteCourseOutcome = async (req, res) => {
    try {
        const { id } = req.params;
        const courseOutcome = await CourseOutcome.findByPk(id);
        
        if (!courseOutcome) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }

        await courseOutcome.destroy();
        
        res.status(200).json({ message: 'Course Outcome deleted successfully' });
    } catch (error) {
        console.error('Error deleting course outcome:', error);
        res.status(500).json({ error: error.message });
    }
};
