const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const { User, Faculty, Batch, Semester, Subject, UniqueSubDegree, UniqueSubDiploma, ComponentWeightage, ComponentMarks, AssignSubjects, CourseOutcome, SubjectComponentCo, SubComponents } = require('../models'); // Import models
const BloomsTaxonomy = require('../models/bloomsTaxonomy');
const CoBloomsTaxonomy = require('../models/coBloomsTaxonomy');

// Add Subject
const addSubject = async (req, res) => {
    try {
        const { name, code, courseType, credits, subjectType, semester } = req.body;

        if (courseType === 'degree') {
            await UniqueSubDegree.create({
                sub_code: code,
                sub_name: name,
                sub_credit: credits,
                sub_level: subjectType,
                semester: semester,
                program: 'Degree'
            });
        } else if (courseType === 'diploma') {
            await UniqueSubDiploma.create({
                sub_code: code,
                sub_name: name,
                sub_credit: credits,
                sub_level: subjectType
            });
        } else {
            return res.status(400).json({ error: 'Invalid course type' });
        }

        res.status(201).json({ message: 'Subject added successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Error adding subject', details: error.message });
    }
};

// Get subject with components
const getSubjectWithComponents = async (req, res) => {
    try {
        const { subjectCode } = req.params;

        const subject = await UniqueSubDegree.findOne({
            where: { sub_code: subjectCode },
            include: [
                { model: ComponentWeightage, as: 'weightage' },
                { model: ComponentMarks, as: 'marks' }
            ]
        });

        if (!subject) {
            return res.status(404).json({ error: 'Subject not found' });
        }

        res.status(200).json(subject);
    } catch (error) {
        console.error('Error getting subject with components:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get Subject by Code and Course Type
const getSubjectByCode = async (req, res) => {
    try {
        const { code, courseType } = req.params;
        let subject;

        if (courseType === 'degree') {
            subject = await UniqueSubDegree.findOne({ where: { sub_code: code } });
        } else if (courseType === 'diploma') {
            subject = await UniqueSubDiploma.findOne({ where: { sub_code: code } });
        } else {
            return res.status(400).json({ error: 'Invalid course type' });
        }

        if (!subject) {
            return res.status(404).json({ error: 'Subject not found' });
        }

        res.status(200).json(subject);
    } catch (error) {
        res.status(500).json({ error: 'Error fetching subject', details: error.message });
    }
};
// Add Subject (Check if already assigned to batch & semester)
const assignSubject = async (req, res) => {
    try {
        console.log("Received Request Body:", req.body); // Debugging

        const { subjects } = req.body;
        if (!subjects || !Array.isArray(subjects) || subjects.length === 0) {
            return res.status(400).json({ message: "Invalid or empty subjects array" });
        }

        for (const subject of subjects) {
            const { subjectName, semesterNumber, batchName } = subject;

            if (!subjectName || !semesterNumber || !batchName) {
                return res.status(400).json({ message: "Missing subjectName, semesterNumber, or batchName" });
            }

            const batch = await Batch.findOne({ where: { batchName } });
            if (!batch) {
                return res.status(404).json({ message: `Batch '${batchName}' not found` });
            }

            const semester = await Semester.findOne({ where: { semesterNumber, batchId: batch.id } });
            if (!semester) {
                return res.status(404).json({ message: `Semester '${semesterNumber}' not found for batch '${batchName}'` });
            }

            const existingSubject = await Subject.findOne({
                where: { subjectName, semesterId: semester.id, batchId: batch.id }
            });

            if (existingSubject) {
                return res.status(400).json({ message: `Subject '${subjectName}' already assigned to this batch and semester` });
            }

            await Subject.create({ subjectName, semesterId: semester.id, batchId: batch.id });
        }

        res.status(201).json({ message: "Subjects assigned successfully" });
    } catch (error) {
        console.error("Error assigning subjects:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// Delete Subject
const deleteSubject = async (req, res) => {
    try {
        const { code, courseType } = req.params;
        let deleted;

        if (courseType === 'degree') {
            deleted = await UniqueSubDegree.destroy({ where: { sub_code: code } });
        } else if (courseType === 'diploma') {
            deleted = await UniqueSubDiploma.destroy({ where: { sub_code: code } });
        } else {
            return res.status(400).json({ error: 'Invalid course type' });
        }

        if (!deleted) {
            return res.status(404).json({ error: 'Subject not found' });
        }

        res.status(200).json({ message: 'Subject deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Error deleting subject', details: error.message });
    }
};

// Function to add a unique subject for Degree
const addUniqueSubDegree = async (req, res) => {
    try {
        const { sub_code, sub_level, sub_name, sub_credit } = req.body;

        if (!sub_code || !sub_level || !sub_name || !sub_credit) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        const subject = await UniqueSubDegree.create({ sub_code, sub_level, sub_name, sub_credit });
        return res.status(201).json({ message: 'Degree subject added successfully', subject });
    } catch (error) {
        return res.status(500).json({ message: 'Error adding degree subject', error: error.message });
    }
};

// Function to add a unique subject for Diploma
const addUniqueSubDiploma = async (req, res) => {
    try {
        const { sub_code, sub_level, sub_name, sub_credit } = req.body;

        if (!sub_code || !sub_level || !sub_name || !sub_credit) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        const subject = await UniqueSubDiploma.create({ sub_code, sub_level, sub_name, sub_credit });
        return res.status(201).json({ message: 'Diploma subject added successfully', subject });
    } catch (error) {
        return res.status(500).json({ message: 'Error adding diploma subject', error: error.message });
    }
};

const getDropdownData = async (req, res) => {
    try {
        const subjects = await UniqueSubDegree.findAll();

        const batches = [...new Set(subjects.map((s) => s.batch))];
        const semesters = [...new Set(subjects.map((s) => s.semester))];
        const programs = [...new Set(subjects.map((s) => s.program))];

        return res.status(200).json({ subjects, batches, semesters, programs });
    } catch (error) {
        return res.status(500).json({ message: "Error fetching data", error: error.message });
    }
};

const getSubjects = async (req, res) => {
    try {
        const subjects = await UniqueSubDegree.findAll();


        return res.status(200).json({ subjects });
    } catch (error) {
        return res.status(500).json({ message: "Error fetching subjects", error: error.message });
    }
};

const getSubjectsByBatchAndSemester = async (req, res) => {
    try {
        const { batchName, semesterNumber } = req.params;

        // Find batch ID from batchName
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // Find semester where batchId matches
        const semester = await Semester.findOne({ where: { semesterNumber, batchId: batch.id } });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found for this batch" });
        }

        // Fetch subjects for the given batch and semester
        const subjects = await Subject.findAll({ where: { semesterId: semester.id, batchId: batch.id } });

        if (subjects.length === 0) {
            return res.status(404).json({ message: "No subjects found for this semester and batch" });
        }

        // Get subject names from subjects
        const subjectNames = subjects.map(s => s.subjectName);

        // Fetch sub_code and sub_level from UniqueSubDegree using sub_name
        const uniqueSubs = await UniqueSubDegree.findAll({
            where: { sub_name: { [Op.in]: subjectNames } },
            attributes: ["sub_name", "sub_code", "sub_level"], // Fetch only required attributes
        });

        // Send the response properly formatted
        res.status(200).json({
            subjects,
            uniqueSubjects: uniqueSubs
        });
    } catch (error) {
        console.error("Error fetching subjects:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};



const getSubjectsByBatchSemesterandFaculty = async (req, res) => {
    try {
        const { batchName, semesterNumber, facultyId } = req.body; // Read from request body
        console.log("Received:", batchName, semesterNumber, facultyId);

        if (!batchName || !semesterNumber || !facultyId) {
            return res.status(400).json({ message: "Missing required fields" });
        }

        // Find faculty name from Users table using facultyId
        const faculty = await User.findOne({ where: { id: facultyId }, attributes: ["name"] });
        if (!faculty) {
            return res.status(404).json({ message: "Faculty not found" });
        }
        console.log("Faculty Name:", faculty.name);

        // Fetch all subject codes assigned to the faculty from AssignSubjects table
        const assignedSubjects = await AssignSubjects.findAll({
            where: { facultyId },
            attributes: ["subjectCode"], // Fetch only subject codes
        });

        if (!assignedSubjects.length) {
            console.log("No assigned subjects found for this faculty.");
        } else {
            const subjectCodes = assignedSubjects.map(sub => sub.subjectCode);
            console.log("Assigned Subject Codes:", subjectCodes);
        }

        // Find batch ID from batchName
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // Find semester where batchId matches
        const semester = await Semester.findOne({ where: { semesterNumber, batchId: batch.id } });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found for this batch" });
        }

        // Fetch subjects where facultyName matches the fetched faculty's name
        const subjects = await Subject.findAll({
            where: { semesterId: semester.id, batchId: batch.id, facultyName: faculty.name }
        });

        if (!subjects.length) {
            return res.status(404).json({ message: "No subjects found for this semester, batch, and faculty" });
        }

        // Get subject names from subjects
        const subjectNames = subjects.map(s => s.subjectName);

        // Fetch sub_code and sub_level from UniqueSubDegree using sub_name
        const uniqueSubs = await UniqueSubDegree.findAll({
            where: { sub_name: { [Op.in]: subjectNames } },
            attributes: ["sub_name", "sub_code", "sub_level"], // Fetch only required attributes
        });

        // Send the response properly formatted
        res.status(200).json({
            facultyName: faculty.name,
            assignedSubjects,
            subjects,
            uniqueSubjects: uniqueSubs
        });
    } catch (error) {
        console.error("Error fetching subjects:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};


const addSubjectWithComponents = async (req, res) => {
    try {
        console.log('Received request body:', req.body);
        const { subject, name, credits, type, components, courseOutcomes, bloomsTaxonomy } = req.body;

        // Validate required fields
        if (!subject || !name || !credits) {
            return res.status(400).json({ error: 'Subject code, name, and credits are required' });
        }

        // Validate components
        if (!Array.isArray(components)) {
            return res.status(400).json({ error: 'Components must be an array' });
        }

        // Validate course outcomes
        if (!Array.isArray(courseOutcomes)) {
            return res.status(400).json({ error: 'Course outcomes must be an array' });
        }

        // Check if subject already exists
        const existingSubject = await UniqueSubDegree.findOne({ where: { sub_code: subject } });
        if (existingSubject) {
            return res.status(400).json({ error: 'Subject already exists', subject: existingSubject });
        }

        // Create subject with required fields
        const validType = type && ['central', 'department'].includes(type) ? type : 'central';

        console.log('Creating subject with type:', validType);

        const subjectRecord = await UniqueSubDegree.create({
            sub_code: subject,
            sub_name: name,
            sub_credit: credits,
            sub_level: validType,
            program: 'Degree'      // Default program
        });

        console.log('Created subject record:', subjectRecord);

        // Create course outcomes
        const createdCOs = await Promise.all(
            courseOutcomes.map(async (co) => {
                if (!co.text || co.text.trim() === '') {
                    throw new Error(`Course outcome ${co.id} description is required`);
                }
                console.log('Creating CO with data:', {
                    subject_id: subjectRecord.sub_code,
                    co_code: co.id,
                    description: co.text
                });
                const createdCO = await CourseOutcome.create({
                    subject_id: subjectRecord.sub_code,
                    co_code: co.id,
                    description: co.text
                });
                console.log('Created CO:', createdCO);
                return createdCO;
            })
        );

        console.log('Created all COs:', createdCOs);

        // Create Blooms Taxonomy associations
        if (bloomsTaxonomy) {
            console.log('Processing Blooms Taxonomy associations:', bloomsTaxonomy);
            for (const [coId, bloomsIds] of Object.entries(bloomsTaxonomy)) {
                const co = createdCOs.find(co => co.co_code === coId);
                if (co && Array.isArray(bloomsIds)) {
                    console.log(`Creating associations for CO ${coId} with Blooms IDs:`, bloomsIds);
                    try {
                        // First, delete any existing associations for this CO
                        await CoBloomsTaxonomy.destroy({
                            where: { course_outcome_id: co.id }
                        });

                        // Create new associations one by one
                        for (const bloomsId of bloomsIds) {
                            try {
                                await CoBloomsTaxonomy.create({
                                    course_outcome_id: co.id,
                                    blooms_taxonomy_id: bloomsId
                                });
                                console.log(`Successfully created association: CO ${co.id} - Blooms ${bloomsId}`);
                            } catch (assocError) {
                                console.error(`Error creating individual association for CO ${co.id} and Blooms ${bloomsId}:`, assocError);
                                // Continue with other associations even if one fails
                            }
                        }
                    } catch (error) {
                        console.error(`Error processing Blooms associations for CO ${coId}:`, error);
                        // Continue with other COs even if one fails
                    }
                } else {
                    console.log(`Skipping invalid Blooms association for CO ${coId}:`, { co, bloomsIds });
                }
            }
        }

        // Map component names from frontend to database
        // Both ComponentWeightage and ComponentMarks now use 'cse'
        const componentMap = {
            'CA': 'cse',
            'CSE': 'cse',
            'ESE': 'ese',
            'IA': 'ia',
            'TW': 'tw',
            'VIVA': 'viva'
        };

        // Prepare weightage and marks data
        const weightageData = { subjectId: subject };
        const marksData = { subjectId: subject };

        // Process components
        for (const component of components) {
            const dbField = componentMap[component.name];
            
            if (dbField) {
                weightageData[dbField] = component.weightage;
                marksData[dbField] = component.totalMarks;
            }
        }

        console.log('Creating weightage with data:', weightageData);
        // Create weightage and marks records
        const weightage = await ComponentWeightage.create(weightageData);
        console.log('Created weightage:', weightage);

        console.log('Creating marks with data:', marksData);
        const marks = await ComponentMarks.create(marksData);
        console.log('Created marks:', marks);

        // Process and create sub-components
        const createdSubComponents = [];
        console.log('Starting sub-component creation process...');
        for (const component of components) {
            if (component.subcomponents && Array.isArray(component.subcomponents) && component.subcomponents.length > 0) {
                console.log(`Processing ${component.subcomponents.length} subcomponents for ${component.name}:`, component.subcomponents);

                for (const subComponent of component.subcomponents) {
                    // Check if sub-component has a name (enabled is not always sent from frontend)
                    if (subComponent.name && subComponent.name.trim() !== '') {
                        try {
                            console.log(`Creating sub-component: ${subComponent.name} for ${component.name}`);
                            console.log('Sub-component data to create:', {
                                componentWeightageId: weightage.id,
                                componentType: component.name,
                                subComponentName: subComponent.name,
                                weightage: subComponent.weightage || 0,
                                totalMarks: subComponent.totalMarks || 0,
                                selectedCOs: subComponent.selectedCOs || [],
                                isEnabled: subComponent.enabled !== undefined ? subComponent.enabled : true
                            });

                            const subComponentRecord = await SubComponents.create({
                                componentWeightageId: weightage.id,
                                componentType: component.name,
                                subComponentName: subComponent.name,
                                weightage: subComponent.weightage || 0,
                                totalMarks: subComponent.totalMarks || 0,
                                selectedCOs: subComponent.selectedCOs || [],
                                isEnabled: subComponent.enabled !== undefined ? subComponent.enabled : true
                            });
                            createdSubComponents.push(subComponentRecord);
                            console.log(`✅ Successfully created sub-component: ${subComponent.name} for ${component.name} with ID: ${subComponentRecord.id}`);
                        } catch (subError) {
                            console.error(`❌ Error creating sub-component ${subComponent.name}:`, subError);
                            console.error('Sub-component error details:', subError.message);
                            console.error('Full error:', subError);
                        }
                    } else {
                        console.log(`Skipping sub-component with empty name:`, subComponent);
                    }
                }
            }
        }

        // Collect all created associations
        let allAssociations = [];

        // Create component-CO associations
        for (const coRecord of createdCOs) { // Iterate through each created Course Outcome
            const associatedComponentNames = [];
            // Find all components from the input `components` array that are associated with this coRecord
            for (const inputComponent of components) {
                // Ensure componentMap has the component and selectedCOs is valid
                if (componentMap[inputComponent.name] && inputComponent.selectedCOs && Array.isArray(inputComponent.selectedCOs)) {
                    if (inputComponent.selectedCOs.includes(coRecord.co_code)) {
                        associatedComponentNames.push(inputComponent.name);
                    }
                }
            }

            if (associatedComponentNames.length > 0) {
                try {
                    const componentsString = associatedComponentNames.join(',');
                    const association = await SubjectComponentCo.create({
                        subject_component_id: weightage.id, // ID of the row in ComponentWeightage for this subject
                        course_outcome_id: coRecord.id,    // ID of the CourseOutcome
                        component: componentsString        // Comma-separated string of component names
                    });
                    allAssociations.push(association);
                } catch (error) {
                    console.error(`Error creating SubjectComponentCo association for CO ID ${coRecord.id}:`, error);
                    // If this is part of a transaction, ensure rollback on error.
                    // For now, logging and continuing. Consider implications for data consistency.
                }
            }
        }

        res.status(201).json({
            subject: subjectRecord,
            weightage,
            marks,
            courseOutcomes: createdCOs,
            subjectComponentCos: allAssociations,
            subComponents: createdSubComponents,
            message: 'Subject, components, sub-components, course outcomes, and Blooms Taxonomy levels added successfully'
        });

    } catch (error) {
        console.error('Error in addSubjectWithComponents:', error);
        console.error('Error details:', {
            name: error.name,
            message: error.message,
            stack: error.stack,
            errors: error.errors
        });
        res.status(500).json({
            error: error.message,
            type: error.name,
            details: error.errors?.map(e => e.message) || []
        });
    }
};

const getSubjectComponentsWithSubjectCode = async (req, res) => {
    try {
        const { subjectCode } = req.params;
        console.log('Fetching components for subject code:', subjectCode);

        // Find the subject by code
        const subject = await UniqueSubDegree.findOne({ where: { sub_code: subjectCode } });
        if (!subject) {
            console.log('Subject not found with code:', subjectCode);
            return res.status(404).json({ error: 'Subject not found' });
        }

        console.log('Found subject:', subject.sub_code, subject.sub_name);

        // Use the subject's sub_code as the subjectId in the related tables
        const weightage = await ComponentWeightage.findOne({ where: { subjectId: subject.sub_code } });
        const marks = await ComponentMarks.findOne({ where: { subjectId: subject.sub_code } });

        console.log('Component weightage:', weightage);
        console.log('Component marks:', marks);

        // Get sub-components if weightage exists
        let subComponents = [];
        if (weightage) {
            subComponents = await SubComponents.findAll({
                where: { componentWeightageId: weightage.id },
                order: [['componentType', 'ASC'], ['subComponentName', 'ASC']]
            });
            console.log('Sub-components:', subComponents);
        }

        // If no weightage or marks are found, return empty objects
        res.status(200).json({
            subject,
            weightage: weightage || {},
            marks: marks || {},
            subComponents: subComponents || []
        });
    } catch (error) {
        console.error('Error getting subject components:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get all unique subjects from UniqueSubDegrees
const getAllUniqueSubjects = async (req, res) => {
    try {
        const subjects = await UniqueSubDegree.findAll();
        console.log(`Found ${subjects.length} unique subjects`);
        return res.status(200).json({ subjects });
    } catch (error) {
        console.error('Error fetching unique subjects:', error);
        return res.status(500).json({ message: "Error fetching unique subjects", error: error.message });
    }
};

// Get subjects by batch
const getSubjectsByBatch = async (req, res) => {
    try {
        const { batchName } = req.params;
        console.log(`Fetching subjects for batch: ${batchName}`);

        // First get the batch ID
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // Get all subjects assigned to this batch
        const subjects = await Subject.findAll({
            where: { batchId: batch.id },
            attributes: ['id', 'subjectName', 'batchId', 'semesterId']
        });

        // Get the unique subject codes from UniqueSubDegree that match these subjects
        const uniqueSubjects = await UniqueSubDegree.findAll();

        return res.status(200).json({
            subjects,
            uniqueSubjects
        });
    } catch (error) {
        console.error('Error fetching subjects by batch:', error);
        return res.status(500).json({ message: "Error fetching subjects by batch", error: error.message });
    }
};

// Get all subjects with their related information
const getAllSubjectsWithDetails = async (req, res) => {
    try {
        // Find all subjects with their related batch and semester information
        const subjects = await Subject.findAll({
            include: [
                {
                    model: Batch,
                    attributes: ['batchName', 'courseType']
                },
                {
                    model: Semester,
                    attributes: ['semesterNumber']
                }
            ]
        });

        if (!subjects || subjects.length === 0) {
            return res.status(404).json({ message: "No subjects found" });
        }

        // Get the unique subject codes and names from UniqueSubDegree
        const subjectNames = subjects.map(s => s.subjectName);
        const uniqueSubjectsInfo = await UniqueSubDegree.findAll({
            where: { sub_name: { [Op.in]: subjectNames } },
            attributes: ['sub_code', 'sub_name', 'sub_credit', 'sub_level', 'program']
        });

        // Map the unique subject info to each subject
        const subjectsWithDetails = subjects.map(subject => {
            const uniqueInfo = uniqueSubjectsInfo.find(u => u.sub_name === subject.subjectName);
            return {
                id: subject.id,
                subjectName: subject.subjectName,
                batchId: subject.batchId,
                semesterId: subject.semesterId,
                batchName: subject.Batch ? subject.Batch.batchName : null,
                semesterNumber: subject.Semester ? subject.Semester.semesterNumber : null,
                courseType: subject.Batch ? subject.Batch.courseType : null,
                sub_code: uniqueInfo ? uniqueInfo.sub_code : null,
                sub_credit: uniqueInfo ? uniqueInfo.sub_credit : null,
                sub_level: uniqueInfo ? uniqueInfo.sub_level : null,
                program: uniqueInfo ? uniqueInfo.program : null
            };
        });

        return res.status(200).json({ subjects: subjectsWithDetails });
    } catch (error) {
        console.error("Error fetching subjects with details:", error);
        return res.status(500).json({ message: "Error fetching subjects", error: error.message });
    }
};

// Get subjects by batch
const getSubjectsByBatchWithDetails = async (req, res) => {
    try {
        const { batchName } = req.params;

        // Find batch ID from batchName
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // Find all subjects for this batch with their related semester information
        const subjects = await Subject.findAll({
            where: { batchId: batch.id },
            include: [
                {
                    model: Semester,
                    attributes: ['semesterNumber']
                }
            ]
        });

        if (!subjects || subjects.length === 0) {
            return res.status(404).json({ message: "No subjects found for this batch" });
        }

        // Get the unique subject codes and names from UniqueSubDegree
        const subjectNames = subjects.map(s => s.subjectName);
        const uniqueSubjectsInfo = await UniqueSubDegree.findAll({
            where: { sub_name: { [Op.in]: subjectNames } },
            attributes: ['sub_code', 'sub_name', 'sub_credit', 'sub_level', 'program']
        });

        // Map the unique subject info to each subject
        const subjectsWithDetails = subjects.map(subject => {
            const uniqueInfo = uniqueSubjectsInfo.find(u => u.sub_name === subject.subjectName);
            return {
                id: subject.id,
                subjectName: subject.subjectName,
                batchId: subject.batchId,
                semesterId: subject.semesterId,
                semesterNumber: subject.Semester ? subject.Semester.semesterNumber : null,
                sub_code: uniqueInfo ? uniqueInfo.sub_code : null,
                sub_credit: uniqueInfo ? uniqueInfo.sub_credit : null,
                sub_level: uniqueInfo ? uniqueInfo.sub_level : null,
                program: uniqueInfo ? uniqueInfo.program : null
            };
        });

        return res.status(200).json({ subjects: subjectsWithDetails });
    } catch (error) {
        console.error("Error fetching subjects by batch:", error);
        return res.status(500).json({ message: "Error fetching subjects", error: error.message });
    }
};

// Get subjects by batch and semester
const getSubjectsByBatchAndSemesterWithDetails = async (req, res) => {
    try {
        const { batchName, semesterNumber } = req.params;

        // Find batch ID from batchName
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // Find semester ID from semesterNumber and batchId
        const semester = await Semester.findOne({
            where: {
                semesterNumber: parseInt(semesterNumber),
                batchId: batch.id
            }
        });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found for this batch" });
        }

        // Find all subjects for this batch and semester
        const subjects = await Subject.findAll({
            where: {
                batchId: batch.id,
                semesterId: semester.id
            }
        });

        if (!subjects || subjects.length === 0) {
            return res.status(404).json({ message: "No subjects found for this batch and semester" });
        }

        // Get the unique subject codes and names from UniqueSubDegree
        const subjectNames = subjects.map(s => s.subjectName);
        const uniqueSubjectsInfo = await UniqueSubDegree.findAll({
            where: { sub_name: { [Op.in]: subjectNames } },
            attributes: ['sub_code', 'sub_name', 'sub_credit', 'sub_level', 'program']
        });

        // Map the unique subject info to each subject
        const subjectsWithDetails = subjects.map(subject => {
            const uniqueInfo = uniqueSubjectsInfo.find(u => u.sub_name === subject.subjectName);
            return {
                id: subject.id,
                subjectName: subject.subjectName,
                batchId: subject.batchId,
                semesterId: subject.semesterId,
                semesterNumber: parseInt(semesterNumber),
                sub_code: uniqueInfo ? uniqueInfo.sub_code : null,
                sub_credit: uniqueInfo ? uniqueInfo.sub_credit : null,
                sub_level: uniqueInfo ? uniqueInfo.sub_level : null,
                program: uniqueInfo ? uniqueInfo.program : null
            };
        });

        return res.status(200).json({ subjects: subjectsWithDetails });
    } catch (error) {
        console.error("Error fetching subjects by batch and semester:", error);
        return res.status(500).json({ message: "Error fetching subjects", error: error.message });
    }
};

module.exports = {
    getSubjectsByBatchAndSemester,
    addSubject,
    getSubjectWithComponents,
    addSubjectWithComponents,
    getDropdownData,
    getSubjectsByBatchSemesterandFaculty,
    assignSubject,
    getSubjectByCode,
    deleteSubject,
    getSubjects,
    addUniqueSubDegree,
    addUniqueSubDiploma,
    getSubjectComponentsWithSubjectCode,
    getAllUniqueSubjects,
    getSubjectsByBatch,
    getAllSubjectsWithDetails,
    getSubjectsByBatchWithDetails,
    getSubjectsByBatchAndSemesterWithDetails
};
