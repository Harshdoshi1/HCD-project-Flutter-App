const SubjectComponentCo = require('../models/subjectComponentCo');
const SubjectComponent = require('../models/subjectComponent'); // Assuming model path
const CourseOutcome = require('../models/courseOutcome'); // Assuming model path

// Get all COs for a specific subject component
exports.getCOsBySubjectComponent = async (req, res) => {
    try {
        const { subjectComponentId } = req.params;
        
        const componentExists = await SubjectComponent.findByPk(subjectComponentId);
        if (!componentExists) {
            return res.status(404).json({ message: 'Subject Component not found' });
        }

        const componentCOs = await SubjectComponentCo.findAll({
            where: { subject_component_id: subjectComponentId },
            include: [{ model: CourseOutcome }] // To get CO details
        });
        res.status(200).json(componentCOs.map(link => link.CourseOutcome));
    } catch (error) {
        console.error('Error fetching COs for subject component:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get all subject components for a specific CO
exports.getSubjectComponentsByCO = async (req, res) => {
    try {
        const { courseOutcomeId } = req.params;

        const coExists = await CourseOutcome.findByPk(courseOutcomeId);
        if (!coExists) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }

        const componentCOs = await SubjectComponentCo.findAll({
            where: { course_outcome_id: courseOutcomeId },
            include: [{ model: SubjectComponent }] // To get component details
        });
        res.status(200).json(componentCOs.map(link => link.SubjectComponent));
    } catch (error) {
        console.error('Error fetching subject components for CO:', error);
        res.status(500).json({ error: error.message });
    }
};
