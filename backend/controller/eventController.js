const EventMaster = require('../models/EventMaster');
const EventOutcomes = require('../models/EventOutcomes');
const EventOutcomeMapping = require('../models/EventOutcomeMapping');
const { sequelize } = require('../models');

// Get all events with their associated outcomes
exports.getAllEvents = async (req, res) => {
    try {
        const events = await EventMaster.findAll({
            include: [{
                model: EventOutcomes,
                as: 'outcomes',
                through: { attributes: [] }, // Don't include join table attributes
                attributes: ['outcome_id', 'outcome', 'outcome_type']
            }]
        });

        res.status(200).json({
            success: true,
            data: events
        });
    } catch (error) {
        console.error('Error fetching events:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching events',
            error: error.message
        });
    }
};

// Create a new event with outcome mapping
exports.createEvent = async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const {
            eventId,
            eventName,
            eventType,
            eventCategory,
            points,
            duration,
            eventDate,
            outcomes
        } = req.body;

        // Create the event
        const event = await EventMaster.create({
            eventId,
            eventName,
            eventType,
            eventCategory,
            points: parseInt(points),
            duration: duration ? parseInt(duration) : null,
            date: eventDate
        }, { transaction });

        // If outcomes are provided, create the mappings
        if (outcomes && outcomes.length > 0) {
            const mappingData = outcomes.map(outcomeId => ({
                eventId: event.eventId,
                outcomeId: parseInt(outcomeId)
            }));

            await EventOutcomeMapping.bulkCreate(mappingData, { transaction });
        }

        await transaction.commit();

        // Fetch the created event with outcomes
        const createdEvent = await EventMaster.findByPk(event.eventId, {
            include: [{
                model: EventOutcomes,
                as: 'outcomes',
                through: { attributes: [] },
                attributes: ['outcome_id', 'outcome', 'outcome_type']
            }]
        });

        res.status(201).json({
            success: true,
            message: 'Event created successfully',
            data: createdEvent
        });
    } catch (error) {
        await transaction.rollback();
        console.error('Error creating event:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating event',
            error: error.message
        });
    }
};

// Get event by ID with outcomes
exports.getEventById = async (req, res) => {
    try {
        const { eventId } = req.params;

        const event = await EventMaster.findByPk(eventId, {
            include: [{
                model: EventOutcomes,
                as: 'outcomes',
                through: { attributes: [] },
                attributes: ['outcome_id', 'outcome', 'outcome_type']
            }]
        });

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        res.status(200).json({
            success: true,
            data: event
        });
    } catch (error) {
        console.error('Error fetching event:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching event',
            error: error.message
        });
    }
};

// Update event and its outcomes
exports.updateEvent = async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { eventId } = req.params;
        const {
            eventName,
            eventType,
            eventCategory,
            points,
            duration,
            eventDate,
            outcomes
        } = req.body;

        const event = await EventMaster.findByPk(eventId);
        if (!event) {
            await transaction.rollback();
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Update event details
        await event.update({
            eventName,
            eventType,
            eventCategory,
            points: parseInt(points),
            duration: duration ? parseInt(duration) : null,
            date: eventDate
        }, { transaction });

        // Remove existing outcome mappings
        await EventOutcomeMapping.destroy({
            where: { eventId },
            transaction
        });

        // Create new outcome mappings if provided
        if (outcomes && outcomes.length > 0) {
            const mappingData = outcomes.map(outcomeId => ({
                eventId,
                outcomeId: parseInt(outcomeId)
            }));

            await EventOutcomeMapping.bulkCreate(mappingData, { transaction });
        }

        await transaction.commit();

        // Fetch updated event with outcomes
        const updatedEvent = await EventMaster.findByPk(eventId, {
            include: [{
                model: EventOutcomes,
                as: 'outcomes',
                through: { attributes: [] },
                attributes: ['outcome_id', 'outcome', 'outcome_type']
            }]
        });

        res.status(200).json({
            success: true,
            message: 'Event updated successfully',
            data: updatedEvent
        });
    } catch (error) {
        await transaction.rollback();
        console.error('Error updating event:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating event',
            error: error.message
        });
    }
};

// Delete event and its outcome mappings
exports.deleteEvent = async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { eventId } = req.params;

        // Delete outcome mappings first
        await EventOutcomeMapping.destroy({
            where: { eventId },
            transaction
        });

        // Delete the event
        const deletedEvent = await EventMaster.destroy({
            where: { eventId },
            transaction
        });

        if (!deletedEvent) {
            await transaction.rollback();
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        await transaction.commit();

        res.status(200).json({
            success: true,
            message: 'Event deleted successfully'
        });
    } catch (error) {
        await transaction.rollback();
        console.error('Error deleting event:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting event',
            error: error.message
        });
    }
};
