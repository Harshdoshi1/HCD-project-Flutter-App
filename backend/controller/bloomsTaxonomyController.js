const BloomsTaxonomy = require('../models/bloomsTaxonomy');
const CourseOutcome = require('../models/courseOutcome');
const CoBloomsTaxonomy = require('../models/coBloomsTaxonomy');

// Get all Blooms Taxonomy levels
exports.getAllBloomsLevels = async (req, res) => {
    try {
        const bloomsLevels = await BloomsTaxonomy.findAll();
        res.status(200).json(bloomsLevels);
    } catch (error) {
        console.error('Error fetching Blooms Taxonomy levels:', error);
        res.status(500).json({ error: error.message });
    }
};

// Create a single Blooms Taxonomy level
exports.createBloomsLevel = async (req, res) => {
    try {
        const { name, description } = req.body;
        
        if (!name) {
            return res.status(400).json({ error: 'Name is required' });
        }

        const bloomsLevel = await BloomsTaxonomy.create({
            name,
            description
        });

        res.status(201).json(bloomsLevel);
    } catch (error) {
        console.error('Error creating Blooms Taxonomy level:', error);
        res.status(500).json({ error: error.message });
    }
};

// Create multiple Blooms Taxonomy levels
exports.createBloomsLevels = async (req, res) => {
    try {
        const levels = req.body;
        
        if (!Array.isArray(levels)) {
            return res.status(400).json({ error: 'Request body must be an array' });
        }

        const createdLevels = await BloomsTaxonomy.bulkCreate(levels, {
            ignoreDuplicates: true
        });

        res.status(201).json(createdLevels);
    } catch (error) {
        console.error('Error creating Blooms Taxonomy levels:', error);
        res.status(500).json({ error: error.message });
    }
};

// Associate Blooms Taxonomy levels with a Course Outcome
exports.associateBloomsWithCO = async (req, res) => {
    try {
        const { courseOutcomeId, bloomsTaxonomyIds } = req.body;

        // Validate course outcome exists
        const co = await CourseOutcome.findByPk(courseOutcomeId);
        if (!co) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }

        // Delete existing associations
        await CoBloomsTaxonomy.destroy({
            where: { course_outcome_id: courseOutcomeId }
        });

        // Create new associations
        const associations = bloomsTaxonomyIds.map(bloomsId => ({
            course_outcome_id: courseOutcomeId,
            blooms_taxonomy_id: bloomsId
        }));

        // Create associations one by one to handle potential duplicates
        for (const association of associations) {
            try {
                await CoBloomsTaxonomy.create(association);
            } catch (error) {
                if (error.name === 'SequelizeUniqueConstraintError') {
                    console.log(`Association already exists: ${JSON.stringify(association)}`);
                    continue;
                }
                throw error;
            }
        }

        // Fetch the updated associations
        const updatedAssociations = await CoBloomsTaxonomy.findAll({
            where: { course_outcome_id: courseOutcomeId },
            include: [{
                model: BloomsTaxonomy,
                as: 'bloomsTaxonomy'
            }]
        });

        res.status(200).json({
            message: 'Blooms Taxonomy levels associated successfully',
            associations: updatedAssociations
        });
    } catch (error) {
        console.error('Error associating Blooms Taxonomy levels:', error);
        res.status(500).json({ 
            error: error.message,
            type: error.name,
            details: error.errors?.map(e => e.message) || []
        });
    }
};

// Get Blooms Taxonomy levels for a Course Outcome
exports.getBloomsForCO = async (req, res) => {
    try {
        const { courseOutcomeId } = req.params;

        const co = await CourseOutcome.findByPk(courseOutcomeId, {
            include: [{
                model: BloomsTaxonomy,
                as: 'bloomsLevels'
            }]
        });

        if (!co) {
            return res.status(404).json({ message: 'Course Outcome not found' });
        }

        res.status(200).json(co.bloomsLevels);
    } catch (error) {
        console.error('Error fetching Blooms Taxonomy levels for CO:', error);
        res.status(500).json({ error: error.message });
    }
}; 