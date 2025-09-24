const ExtraCurricularActivity = require("../models/extraCurricularActivity");
const Student = require("../models/students");

// Get activities by enrollment number and semester
const getActivitiesByEnrollmentAndSemester = async (req, res) => {
    try {
        const { enrollmentNumber, semesterId } = req.params;

        const activities = await ExtraCurricularActivity.findAll({
            where: { enrollmentNumber, semesterId },
            include: [
                {
                    model: Student,
                    attributes: ["name", "enrollmentNumber"],
                    where: { enrollmentNumber }
                }
            ]
        });

        res.status(200).json(activities);
    } catch (error) {
        console.error("Error fetching extracurricular activities:", error);
        res.status(500).json({ message: "Error fetching activities", error: error.message });
    }
};

// Add new extracurricular activity
const addActivity = async (req, res) => {
    try {
        const {
            enrollmentNumber,
            semesterId,
            activityName,
            achievementLevel,
            date,
            description,
            certificateUrl,
            score
        } = req.body;

        // Validate required fields
        if (!enrollmentNumber || !semesterId || !activityName || !date || !description) {
            return res.status(400).json({
                message: "Missing required fields",
                required: ["enrollmentNumber", "semesterId", "activityName", "date", "description"]
            });
        }

        // Check if student exists
        const student = await Student.findOne({
            where: { enrollmentNumber }
        });

        if (!student) {
            return res.status(404).json({
                message: "Student not found",
                enrollmentNumber
            });
        }

        // Create new activity
        const newActivity = await ExtraCurricularActivity.create({
            enrollmentNumber,
            semesterId,
            activityName,
            achievementLevel,
            date: new Date(date),
            description,
            certificateUrl,
            score
        });

        res.status(201).json(newActivity);
    } catch (error) {
        console.error("Error creating extracurricular activity:", error);
        res.status(500).json({ message: "Error creating activity", error: error.message });
    }
};

// Update existing extracurricular activity
const updateActivity = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            enrollmentNumber,
            semesterId,
            activityName,
            achievementLevel,
            date,
            description,
            certificateUrl,
            score
        } = req.body;

        // Validate required fields
        if (!enrollmentNumber || !semesterId || !activityName || !date || !description) {
            return res.status(400).json({
                message: "Missing required fields",
                required: ["enrollmentNumber", "semesterId", "activityName", "date", "description"]
            });
        }

        // Check if student exists
        const student = await Student.findOne({
            where: { enrollmentNumber }
        });

        if (!student) {
            return res.status(404).json({
                message: "Student not found",
                enrollmentNumber
            });
        }

        // Update existing activity
        const [updated] = await ExtraCurricularActivity.update({
            enrollmentNumber,
            semesterId,
            activityName,
            achievementLevel,
            date: new Date(date),
            description,
            certificateUrl
        }, {
            where: { id }
        });

        if (updated) {
            const updatedActivity = await ExtraCurricularActivity.findByPk(id, {
                include: [
                    {
                        model: Student,
                        attributes: ["name", "enrollmentNumber"],
                        where: { enrollmentNumber }
                    }
                ]
            });
            res.status(200).json(updatedActivity);
        } else {
            res.status(404).json({ message: 'Activity not found' });
        }
    } catch (error) {
        console.error("Error updating extracurricular activity:", error);
        res.status(500).json({ message: "Error updating activity", error: error.message });
    }
};

// Delete extracurricular activity
const deleteActivity = async (req, res) => {
    try {
        const { activityId } = req.params;
        const deleted = await ExtraCurricularActivity.destroy({
            where: { id: activityId }
        });

        if (deleted) {
            res.status(200).json({ message: 'Activity deleted successfully' });
        } else {
            res.status(404).json({ message: 'Activity not found' });
        }
    } catch (error) {
        console.error("Error deleting extracurricular activity:", error);
        res.status(500).json({ message: "Error deleting activity", error: error.message });
    }
};


const getStudentExtraCurricularActivities = async (req, res) => {
    try {
        const { enrollmentNumber } = req.params;
        console.log("Received enrollment number:", enrollmentNumber);

        const activities = await ExtraCurricularActivity.findAll({
            where: { enrollmentNumber },
            order: [['date', 'DESC']],
            include: [
                {
                    model: Student,
                    attributes: ["name", "enrollmentNumber"]
                }
            ]
        });

        res.status(200).json(activities);
    } catch (error) {
        console.error("Error fetching student's extracurricular activities:", error);
        res.status(500).json({ message: "Error fetching activities", error: error.message });
    }
};

const getextraStudentActivities = async (req, res) => {
    try {
        const { enrollmentNumber } = req.body;
        const activities = await ExtraCurricularActivity.findAll({
            where: { enrollmentNumber }
        });
        res.status(200).json(activities);
    } catch (error) {
        console.error("Error fetching student activities:", error);
        res.status(500).json({ message: "Error fetching activities", error: error.message });
    }
};

const getextraStudentActivitieswithenrollmentandSemester = async (req, res) => {
    try {
        const { enrollmentNumber, semesterId } = req.body;

        if (!enrollmentNumber || !semesterId) {
            return res.status(400).json({
                message: "Missing required fields",
                required: ["enrollmentNumber", "semesterId"]
            });
        }

        const activities = await ExtraCurricularActivity.findAll({
            where: { enrollmentNumber, semesterId }
        });

        if (activities.length === 0) {
            return res.status(200).json({ message: "No activities found for the given enrollment number and semester" });
        }

        res.status(200).json(activities);
    } catch (error) {
        console.error("Error fetching student activities with enrollment and semester:", error);
        res.status(500).json({ message: "Error fetching activities", error: error.message });
    }
};
module.exports = { getextraStudentActivitieswithenrollmentandSemester, getStudentExtraCurricularActivities, getextraStudentActivities, getActivitiesByEnrollmentAndSemester, addActivity, updateActivity, deleteActivity }