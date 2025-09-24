// // const CoCurricularActivity = require("../models/cocurricularActivity");
// const Student = require("../models/students");

// // Add new co-curricular activity
// const addActivity = async (req, res) => {
//     try {
//         // const activityData = {

//         const {
//             enrollmentNumber,
//             semesterId,
//             activityName,
//             achievementLevel,
//             date,
//             description,
//             certificateUrl,
//             score
//         } = req.body;
//         if (!enrollmentNumber || !semesterId || !activityName || !date || !description) {
//             return res.status(400).json({
//                 message: "Missing required fields",
//                 required: ["enrollmentNumber", "semesterId", "activityName", "date", "description"]
//             });
//         }

//         const student = await Student.findOne({
//             where: { enrollmentNumber }
//         });

//         if (!student) {
//             return res.status(404).json({
//                 message: "Student not found",
//                 enrollmentNumber
//             });
//         }


//         // Create new activity
//         const newActivity = await CoCurricularActivity.create({
//             enrollmentNumber,
//             semesterId,
//             activityName,
//             achievementLevel,
//             date: new Date(date),
//             description,
//             certificateUrl,
//             score
//         });

//         // const newActivity = await CoCurricularActivity.create(activityData);
//         res.status(201).json(newActivity);
//     } catch (error) {
//         console.error("Error adding co-curricular activity:", error);
//         if (error.name === 'SequelizeValidationError') {
//             return res.status(400).json({
//                 message: "Validation error",
//                 errors: error.errors.map(err => err.message)
//             });
//         }
//         res.status(500).json({ message: "Error adding activity", error: error.message });
//     }
// };

// // Update existing co-curricular activity
// const updateActivity = async (req, res) => {
//     try {
//         const { activityId } = req.params;
//         const updateData = {
//             activityName: req.body.activityName,
//             achievementLevel: req.body.achievementLevel,
//             date: req.body.date,
//             description: req.body.description,
//             certificateUrl: req.body.certificateUrl,
//             score: req.body.score
//         };

//         const updated = await CoCurricularActivity.update(updateData, {
//             where: { id: activityId }
//         });

//         if (updated[0] === 1) {
//             const updatedActivity = await CoCurricularActivity.findByPk(activityId);
//             res.status(200).json(updatedActivity);
//         } else {
//             res.status(404).json({ message: 'Activity not found' });
//         }
//     } catch (error) {
//         console.error("Error updating co-curricular activity:", error);
//         res.status(500).json({ message: "Error updating activity", error: error.message });
//     }
// };

// // Delete co-curricular activity
// const deleteActivity = async (req, res) => {
//     try {
//         const { activityId } = req.params;
//         const deleted = await CoCurricularActivity.destroy({
//             where: { id: activityId }
//         });

//         if (deleted) {
//             res.status(200).json({ message: 'Activity deleted successfully' });
//         } else {
//             res.status(404).json({ message: 'Activity not found' });
//         }
//     } catch (error) {
//         console.error("Error deleting co-curricular activity:", error);
//         res.status(500).json({ message: "Error deleting activity", error: error.message });
//     }
// };

// // Get all activities for a student by enrollment number
// const getStudentActivities = async (req, res) => {
//     try {
//         const { enrollmentNumber } = req.body;
//         const activities = await CoCurricularActivity.findAll({
//             where: { enrollmentNumber }
//         });
//         res.status(200).json(activities);
//     } catch (error) {
//         console.error("Error fetching student activities:", error);
//         res.status(500).json({ message: "Error fetching activities", error: error.message });
//     }
// };
// const getStudentActivitieswithenrollmentandSemester = async (req, res) => {
//     try {
//         const { enrollmentNumber, semesterId } = req.body;

//         if (!enrollmentNumber || !semesterId) {
//             return res.status(400).json({
//                 message: "Missing required fields",
//                 required: ["enrollmentNumber", "semesterId"]
//             });
//         }

//         const activities = await CoCurricularActivity.findAll({
//             where: { enrollmentNumber, semesterId }
//         });

//         if (activities.length === 0) {
//             return res.status(200).json({ message: "No activities found for the given enrollment number and semester" });
//         }

//         res.status(200).json(activities);
//     } catch (error) {
//         console.error("Error fetching student activities with enrollment and semester:", error);
//         res.status(500).json({ message: "Error fetching activities", error: error.message });
//     }
// };

// module.exports = { getStudentActivities, deleteActivity, updateActivity, addActivity, getStudentActivitieswithenrollmentandSemester };