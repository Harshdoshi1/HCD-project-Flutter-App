const EventOutcomes = require('../models/EventOutcomes');

// Get all event outcomes
exports.getAllEventOutcomes = async (req, res) => {
    try {
        const outcomes = await EventOutcomes.findAll();
        res.status(200).json({
            success: true,
            data: outcomes
        });
    } catch (error) {
        console.error('Error fetching event outcomes:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching event outcomes',
            error: error.message
        });
    }
};

// Get event outcomes by type
exports.getEventOutcomesByType = async (req, res) => {
    try {
        const { outcomeType } = req.params;
        
        if (!['Technical', 'Non-Technical'].includes(outcomeType)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid outcome type. Must be either Technical or Non-Technical'
            });
        }

        const outcomes = await EventOutcomes.findAll({
            where: { outcome_type: outcomeType }
        });

        res.status(200).json({
            success: true,
            data: outcomes
        });
    } catch (error) {
        console.error('Error fetching event outcomes by type:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching event outcomes by type',
            error: error.message
        });
    }
};

// Create a new event outcome
exports.createEventOutcome = async (req, res) => {
    try {
        const { outcome, outcome_type } = req.body;

        if (!outcome || !outcome_type) {
            return res.status(400).json({
                success: false,
                message: 'Both outcome and outcome_type are required'
            });
        }

        if (!['Technical', 'Non-Technical'].includes(outcome_type)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid outcome type. Must be either Technical or Non-Technical'
            });
        }

        const newOutcome = await EventOutcomes.create({
            outcome,
            outcome_type
        });

        res.status(201).json({
            success: true,
            data: newOutcome
        });
    } catch (error) {
        console.error('Error creating event outcome:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating event outcome',
            error: error.message
        });
    }
};

// Update an event outcome
exports.updateEventOutcome = async (req, res) => {
    try {
        const { id } = req.params;
        const { outcome, outcome_type } = req.body;

        const existingOutcome = await EventOutcomes.findByPk(id);

        if (!existingOutcome) {
            return res.status(404).json({
                success: false,
                message: 'Event outcome not found'
            });
        }

        if (outcome_type && !['Technical', 'Non-Technical'].includes(outcome_type)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid outcome type. Must be either Technical or Non-Technical'
            });
        }

        await existingOutcome.update({
            outcome: outcome || existingOutcome.outcome,
            outcome_type: outcome_type || existingOutcome.outcome_type
        });

        res.status(200).json({
            success: true,
            data: existingOutcome
        });
    } catch (error) {
        console.error('Error updating event outcome:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating event outcome',
            error: error.message
        });
    }
};

// Delete an event outcome
exports.deleteEventOutcome = async (req, res) => {
    try {
        const { id } = req.params;

        const outcome = await EventOutcomes.findByPk(id);

        if (!outcome) {
            return res.status(404).json({
                success: false,
                message: 'Event outcome not found'
            });
        }

        await outcome.destroy();

        res.status(200).json({
            success: true,
            message: 'Event outcome deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting event outcome:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting event outcome',
            error: error.message
        });
    }
};