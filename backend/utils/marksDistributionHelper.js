const { 
    StudentMarks,
    ComponentWeightage,
    SubComponents,
    CourseOutcome,
    CoBloomsTaxonomy,
    BloomsTaxonomy,
    SubjectComponentCo,
    StudentBloomsDistribution,
    Student,
    Semester,
    UniqueSubDegree
} = require('../models');
const { Op } = require('sequelize');

/**
 * Calculate weighted marks for a component/subcomponent
 * @param {number} marksObtained - Marks obtained by student
 * @param {number} totalMarks - Total marks of the component/subcomponent
 * @param {number} weightagePercentage - Weightage percentage of component
 * @param {number} maxSubjectMarks - Maximum marks for subject (default 150)
 * @returns {number} Weighted marks
 */
const calculateWeightedMarks = (marksObtained, totalMarks, weightagePercentage, maxSubjectMarks = 150) => {
    if (totalMarks === 0 || !totalMarks) return 0;
    
    // Calculate the allocated marks for this component based on weightage
    const allocatedMarks = (weightagePercentage / 100) * maxSubjectMarks;
    
    // Calculate the percentage of marks obtained in this component
    const percentageObtained = marksObtained / totalMarks;
    
    // Calculate weighted marks
    const weightedMarks = percentageObtained * allocatedMarks;
    
    return parseFloat(weightedMarks.toFixed(2));
};

/**
 * Get COs and their associated Bloom's levels for a component/subcomponent
 * @param {string} subjectId - Subject code
 * @param {number} componentWeightageId - Component weightage ID
 * @param {string} componentType - Component type (ESE, CA, IA, etc.)
 * @param {number} subComponentId - Subcomponent ID (optional)
 * @returns {object} Mapping of COs to Bloom's levels
 */
const getCOsAndBloomsMapping = async (subjectId, componentWeightageId, componentType, subComponentId = null) => {
    const coBloomsMapping = {};
    let selectedCOs = [];
    
    if (subComponentId) {
        // For subcomponents, get COs from SubComponents table
        const subComponent = await SubComponents.findByPk(subComponentId);
        if (subComponent && subComponent.selectedCOs) {
            selectedCOs = subComponent.selectedCOs;
        }
    } else {
        // For main components, get COs from SubjectComponentCo table
        const componentCOs = await SubjectComponentCo.findAll({
            where: {
                subject_component_id: componentWeightageId,
                component: componentType
            },
            include: [{
                model: CourseOutcome,
                as: 'courseOutcome'
            }]
        });
        
        selectedCOs = componentCOs.map(cco => cco.course_outcome_id);
    }
    
    // For each CO, get associated Bloom's levels
    for (const coId of selectedCOs) {
        const coBloomsLinks = await CoBloomsTaxonomy.findAll({
            where: { course_outcome_id: coId },
            include: [{
                model: BloomsTaxonomy,
                as: 'bloomsTaxonomy'
            }]
        });
        
        coBloomsMapping[coId] = coBloomsLinks.map(link => ({
            bloomsId: link.blooms_taxonomy_id,
            bloomsName: link.bloomsTaxonomy ? link.bloomsTaxonomy.name : 'Unknown'
        }));
    }
    
    return coBloomsMapping;
};

/**
 * Calculate and distribute weighted marks to COs and Bloom's levels
 * @param {number} studentId - Student ID
 * @param {string} subjectId - Subject code
 * @param {number} semesterNumber - Semester number
 * @returns {array} Array of distribution records
 */
const calculateAndDistributeMarks = async (studentId, subjectId, semesterNumber) => {
    const distributionRecords = [];
    
    try {
        console.log(`Calculating marks distribution for student ${studentId}, subject ${subjectId}, semester ${semesterNumber}`);
        
        // Get student information
        const student = await Student.findByPk(studentId);
        if (!student) {
            throw new Error('Student not found');
        }
        
        // Get component weightage configuration
        const componentWeightage = await ComponentWeightage.findOne({
            where: { subjectId: subjectId },
            include: [{
                model: SubComponents,
                as: 'subComponents'
            }]
        });
        
        if (!componentWeightage) {
            console.warn(`No component weightage found for subject ${subjectId}`);
            return distributionRecords;
        }
        
        // Get all student marks for this subject and semester
        const studentMarks = await StudentMarks.findAll({
            where: {
                studentId: studentId,
                subjectId: subjectId,
                enrollmentSemester: semesterNumber
            },
            include: [{
                model: SubComponents,
                as: 'subComponent'
            }]
        });
        
        if (studentMarks.length === 0) {
            console.log(`No marks found for student ${studentId} in subject ${subjectId}`);
            return distributionRecords;
        }
        
        // Process each mark entry
        for (const markEntry of studentMarks) {
            let weightagePercentage = 0;
            let coBloomsMapping = {};
            
            if (markEntry.isSubComponent && markEntry.subComponent) {
                // For subcomponents, get weightage from SubComponents table
                weightagePercentage = markEntry.subComponent.weightage;
                coBloomsMapping = await getCOsAndBloomsMapping(
                    subjectId,
                    componentWeightage.id,
                    markEntry.componentType,
                    markEntry.subComponentId
                );
            } else {
                // For main components, get weightage from ComponentWeightage table
                const componentTypeLower = markEntry.componentType.toLowerCase();
                weightagePercentage = componentWeightage[componentTypeLower] || 0;
                
                // Skip if component has no weightage
                if (weightagePercentage === 0) continue;
                
                coBloomsMapping = await getCOsAndBloomsMapping(
                    subjectId,
                    componentWeightage.id,
                    markEntry.componentType,
                    null
                );
            }
            
            // Calculate weighted marks
            const weightedMarks = calculateWeightedMarks(
                markEntry.marksObtained,
                markEntry.totalMarks,
                weightagePercentage,
                150 // Total subject marks fixed at 150
            );
            
            console.log(`Component: ${markEntry.componentType}${markEntry.isSubComponent ? ' - ' + markEntry.componentName : ''}`);
            console.log(`Marks: ${markEntry.marksObtained}/${markEntry.totalMarks}, Weightage: ${weightagePercentage}%, Weighted Marks: ${weightedMarks}`);
            
            // Distribute weighted marks to all associated COs and Bloom's levels
            for (const [coId, bloomsLevels] of Object.entries(coBloomsMapping)) {
                for (const bloom of bloomsLevels) {
                    // Each CO-Bloom combination gets the full weighted marks
                    distributionRecords.push({
                        studentId: studentId,
                        semesterNumber: semesterNumber,
                        subjectId: subjectId,
                        studentMarksSubjectComponentId: markEntry.id,
                        totalMarksOfComponent: markEntry.totalMarks,
                        subComponentWeightage: weightagePercentage,
                        selectedCOs: Object.keys(coBloomsMapping).map(id => parseInt(id)),
                        courseOutcomeId: parseInt(coId),
                        bloomsTaxonomyId: bloom.bloomsId,
                        assignedMarks: weightedMarks,
                        calculatedAt: new Date()
                    });
                }
            }
        }
        
        console.log(`Generated ${distributionRecords.length} distribution records`);
        return distributionRecords;
        
    } catch (error) {
        console.error('Error in calculateAndDistributeMarks:', error);
        throw error;
    }
};

/**
 * Aggregate marks by Bloom's taxonomy level
 * @param {array} distributionRecords - Array of distribution records
 * @returns {object} Aggregated marks by Bloom's level
 */
const aggregateMarksByBlooms = (distributionRecords) => {
    const bloomsAggregation = {};
    
    distributionRecords.forEach(record => {
        if (!bloomsAggregation[record.bloomsTaxonomyId]) {
            bloomsAggregation[record.bloomsTaxonomyId] = {
                totalMarks: 0,
                records: []
            };
        }
        
        // Add marks (not accumulate, as each CO-Bloom pair should have unique marks)
        // Check if this component was already added for this Bloom's level
        const existingComponent = bloomsAggregation[record.bloomsTaxonomyId].records.find(
            r => r.studentMarksSubjectComponentId === record.studentMarksSubjectComponentId
        );
        
        if (!existingComponent) {
            bloomsAggregation[record.bloomsTaxonomyId].totalMarks += record.assignedMarks;
            bloomsAggregation[record.bloomsTaxonomyId].records.push(record);
        }
    });
    
    return bloomsAggregation;
};

/**
 * Main function to process marks distribution for a student
 * @param {number} studentId - Student ID
 * @param {number} semesterNumber - Semester number
 * @param {string} subjectId - Optional subject ID to process specific subject
 */
const processStudentMarksDistribution = async (studentId, semesterNumber, subjectId = null) => {
    try {
        console.log(`Processing marks distribution for student ${studentId}, semester ${semesterNumber}`);
        
        let subjects = [];
        
        if (subjectId) {
            subjects = [{ subjectId }];
        } else {
            // Get all subjects for the student in this semester
            const studentMarks = await StudentMarks.findAll({
                where: {
                    studentId: studentId,
                    enrollmentSemester: semesterNumber
                },
                attributes: ['subjectId'],
                group: ['subjectId']
            });
            
            subjects = studentMarks.map(sm => ({ subjectId: sm.subjectId }));
        }
        
        const allDistributionRecords = [];
        
        for (const subject of subjects) {
            const distributionRecords = await calculateAndDistributeMarks(
                studentId,
                subject.subjectId,
                semesterNumber
            );
            
            allDistributionRecords.push(...distributionRecords);
        }
        
        if (allDistributionRecords.length > 0) {
            // Clear existing distribution records for this student and semester
            await StudentBloomsDistribution.destroy({
                where: {
                    studentId: studentId,
                    semesterNumber: semesterNumber,
                    ...(subjectId ? { subjectId: subjectId } : {})
                }
            });
            
            // Insert new distribution records
            await StudentBloomsDistribution.bulkCreate(allDistributionRecords);
            
            console.log(`Successfully stored ${allDistributionRecords.length} distribution records`);
        }
        
        return {
            success: true,
            recordsCreated: allDistributionRecords.length,
            distributions: allDistributionRecords
        };
        
    } catch (error) {
        console.error('Error in processStudentMarksDistribution:', error);
        throw error;
    }
};

module.exports = {
    calculateWeightedMarks,
    getCOsAndBloomsMapping,
    calculateAndDistributeMarks,
    aggregateMarksByBlooms,
    processStudentMarksDistribution
};
