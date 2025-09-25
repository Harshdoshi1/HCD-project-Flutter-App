# Event Outcomes Management System

This document describes the new Event Outcomes Management system that allows HODs to associate technical and non-technical outcomes with events.

## Overview

The system consists of three main components:
1. **EventOutcomes** - Stores available technical and non-technical outcomes
2. **EventMaster** - Stores event information
3. **EventOutcomeMapping** - Links events to their associated outcomes

## Database Schema

### EventOutcomes Table
- `outcome_id` (INTEGER, PRIMARY KEY, AUTO_INCREMENT)
- `outcome` (STRING) - Name of the outcome
- `outcome_type` (ENUM) - Either 'Technical' or 'Non-Technical'

### EventMaster Table
- `eventId` (STRING, PRIMARY KEY)
- `eventName` (STRING)
- `eventType` (ENUM) - 'co-curricular' or 'extra-curricular'
- `eventCategory` (STRING)
- `points` (INTEGER)
- `duration` (INTEGER, optional)
- `date` (DATE)

### EventOutcomeMapping Table
- `id` (INTEGER, PRIMARY KEY, AUTO_INCREMENT)
- `eventId` (STRING, FOREIGN KEY to EventMaster)
- `outcomeId` (INTEGER, FOREIGN KEY to EventOutcomes)

## API Endpoints

### Event Outcomes
- `GET /api/event-outcomes` - Get all outcomes
- `GET /api/event-outcomes/type/:outcomeType` - Get outcomes by type (Technical/Non-Technical)
- `POST /api/event-outcomes` - Create new outcome
- `PUT /api/event-outcomes/:id` - Update outcome
- `DELETE /api/event-outcomes/:id` - Delete outcome

### Events
- `GET /api/events/all` - Get all events with outcomes
- `GET /api/events/:eventId` - Get specific event with outcomes
- `POST /api/events/createEvent` - Create new event with outcomes
- `PUT /api/events/:eventId` - Update event and outcomes
- `DELETE /api/events/:eventId` - Delete event and outcome mappings

## Frontend Features

### AddEventForm
- Displays technical and non-technical outcomes as checkboxes
- Allows HODs to select which outcomes are associated with an event
- Form validation and error handling
- Loading states during submission

### EventManagement
- Shows all events in a grid layout
- Displays associated outcomes as colored tags
- Technical outcomes shown in blue, non-technical in green
- Filter events by type (All, Co-Curricular, Extra-Curricular)

## Setup Instructions

1. **Database Setup**
   ```bash
   # Run the database sync
   node sync.js
   
   # Initialize sample outcomes (optional)
   mysql -u username -p database_name < scripts/init_event_outcomes.sql
   ```

2. **Test the System**
   ```bash
   # Test the database connections and associations
   node test-event-outcomes.js
   ```

3. **Start the Backend**
   ```bash
   npm start
   ```

## Sample Data

The system comes with 20 pre-defined outcomes:
- **Technical**: Problem Solving, Critical Thinking, Analytical Skills, Programming Skills, Data Analysis, System Design, Algorithm Design, Database Management, Network Security, Software Testing
- **Non-Technical**: Leadership, Teamwork, Communication, Time Management, Creativity, Adaptability, Presentation Skills, Project Management, Problem Analysis, Innovation

## Usage Workflow

1. HOD navigates to Events section
2. Clicks "Add Event" button
3. Fills in event details (ID, name, type, category, points, duration, date)
4. Selects relevant technical and non-technical outcomes from checkboxes
5. Saves the event
6. Event appears in the events grid with associated outcomes displayed as tags

## Benefits

- **Structured Learning**: Events are now linked to specific learning outcomes
- **Assessment Tracking**: Faculty can track which outcomes students achieve through events
- **Curriculum Alignment**: Events can be aligned with course objectives
- **Visual Impact**: Color-coded outcome tags make it easy to see event focus areas
- **Data Analysis**: Rich data for analyzing student participation and achievement

## Technical Notes

- Uses Sequelize ORM with proper associations
- Implements database transactions for data integrity
- Frontend uses React hooks for state management
- Responsive design with modern CSS styling
- Error handling and loading states throughout
