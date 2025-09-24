const StudentPoints = require('./StudentPoints');
const EventMaster = require('./EventMaster');
const ParticipationType = require('./participationTypes');
const EventOutcomes = require('./EventOutcomes');
const EventOutcomeMapping = require('./EventOutcomeMapping');
const UniqueSubDegree = require('./uniqueSubDegree');
const CourseOutcome = require('./courseOutcome');
const ComponentWeightage = require('./componentWeightage');
const SubjectComponentCo = require('./subjectComponentCo');
const BloomsTaxonomy = require('./bloomsTaxonomy');
const CoBloomsTaxonomy = require('./coBloomsTaxonomy');
const ClassSection = require('./classSection');
const Semester = require('./semester');
const Batch = require('./batch');
const SubComponents = require('./subComponents');
const StudentMarks = require('./studentMarks');
const Student = require('./students');
const User = require('./users');
const StudentBloomsDistribution = require('./StudentBloomsDistribution');

// Set up associations between StudentPoints and EventMaster without enforcing foreign key constraints
StudentPoints.belongsTo(EventMaster, {
  foreignKey: 'eventId',
  targetKey: 'eventId',
  as: 'event',
  constraints: false // Don't enforce foreign key constraints
});

// Set up associations between StudentPoints and ParticipationType without enforcing foreign key constraints
StudentPoints.belongsTo(ParticipationType, {
  foreignKey: 'participationTypeId',
  targetKey: 'id',
  as: 'participationType',
  constraints: false // Don't enforce foreign key constraints
});

// --- Event-Outcome Associations ---

// EventMaster can have many EventOutcomes through EventOutcomeMapping
EventMaster.belongsToMany(EventOutcomes, {
  through: EventOutcomeMapping,
  foreignKey: 'eventId',
  otherKey: 'outcomeId',
  as: 'outcomes'
});

// EventOutcomes can be associated with many EventMaster through EventOutcomeMapping
EventOutcomes.belongsToMany(EventMaster, {
  through: EventOutcomeMapping,
  foreignKey: 'outcomeId',
  otherKey: 'eventId',
  as: 'events'
});

// EventOutcomeMapping belongs to EventMaster
EventOutcomeMapping.belongsTo(EventMaster, {
  foreignKey: 'eventId',
  as: 'event'
});

// EventOutcomeMapping belongs to EventOutcomes
EventOutcomeMapping.belongsTo(EventOutcomes, {
  foreignKey: 'outcomeId',
  as: 'outcome'
});

// --- ClassSection Associations ---

// Semester has many ClassSections
Semester.hasMany(ClassSection, {
  foreignKey: 'semesterId',
  as: 'classSections'
});

// Batch has many ClassSections
Batch.hasMany(ClassSection, {
  foreignKey: 'batchId',
  as: 'classSections'
});

// ClassSection belongs to Semester
ClassSection.belongsTo(Semester, {
  foreignKey: 'semesterId',
  as: 'semester'
});

// ClassSection belongs to Batch
ClassSection.belongsTo(Batch, {
  foreignKey: 'batchId',
  as: 'batch'
});

// --- CourseOutcome Associations ---

// UniqueSubDegree (Subject) has many CourseOutcomes
UniqueSubDegree.hasMany(CourseOutcome, {
  foreignKey: 'subject_id',
  as: 'courseOutcomes' // Alias for fetching COs from a Subject
});
// CourseOutcome belongs to one UniqueSubDegree (Subject)
CourseOutcome.belongsTo(UniqueSubDegree, {
  foreignKey: 'subject_id',
  as: 'subject' // Alias for fetching Subject from a CO
});

// --- SubjectComponentCo Associations (Many-to-Many between ComponentWeightage and CourseOutcome) ---

// ComponentWeightage (Subject Component) can have many CourseOutcomes through SubjectComponentCo
ComponentWeightage.belongsToMany(CourseOutcome, {
  through: SubjectComponentCo,
  foreignKey: 'subject_component_id', // Foreign key in SubjectComponentCo linking to ComponentWeightage
  otherKey: 'course_outcome_id',    // Foreign key in SubjectComponentCo linking to CourseOutcome
  as: 'associatedCourseOutcomes'    // Alias for fetching COs from a ComponentWeightage
});

// CourseOutcome can be associated with many ComponentWeightages (Subject Components) through SubjectComponentCo
CourseOutcome.belongsToMany(ComponentWeightage, {
  through: SubjectComponentCo,
  foreignKey: 'course_outcome_id',       // Foreign key in SubjectComponentCo linking to CourseOutcome
  otherKey: 'subject_component_id', // Foreign key in SubjectComponentCo linking to ComponentWeightage
  as: 'associatedComponents'       // Alias for fetching ComponentWeightages from a CO
});

// Explicitly define relationships for the join table SubjectComponentCo
// SubjectComponentCo belongs to one ComponentWeightage
SubjectComponentCo.belongsTo(ComponentWeightage, {
  foreignKey: 'subject_component_id',
  as: 'componentWeightage' // Alias for fetching ComponentWeightage from SubjectComponentCo
});

// SubjectComponentCo belongs to one CourseOutcome
SubjectComponentCo.belongsTo(CourseOutcome, {
  foreignKey: 'course_outcome_id',
  as: 'courseOutcome' // Alias for fetching CourseOutcome from SubjectComponentCo
});

// --- Blooms Taxonomy Associations ---

// CourseOutcome can have many Blooms Taxonomy levels through CoBloomsTaxonomy
CourseOutcome.belongsToMany(BloomsTaxonomy, {
  through: CoBloomsTaxonomy,
  foreignKey: 'course_outcome_id',
  otherKey: 'blooms_taxonomy_id',
  as: 'bloomsLevels'
});

// Blooms Taxonomy can be associated with many Course Outcomes through CoBloomsTaxonomy
BloomsTaxonomy.belongsToMany(CourseOutcome, {
  through: CoBloomsTaxonomy,
  foreignKey: 'blooms_taxonomy_id',
  otherKey: 'course_outcome_id',
  as: 'courseOutcomes'
});

// CoBloomsTaxonomy belongs to CourseOutcome
CoBloomsTaxonomy.belongsTo(CourseOutcome, {
  foreignKey: 'course_outcome_id',
  as: 'courseOutcome'
});

// CoBloomsTaxonomy belongs to BloomsTaxonomy
CoBloomsTaxonomy.belongsTo(BloomsTaxonomy, {
  foreignKey: 'blooms_taxonomy_id',
  as: 'bloomsTaxonomy'
});

// --- SubComponents Associations ---

// ComponentWeightage has many SubComponents
ComponentWeightage.hasMany(SubComponents, {
  foreignKey: 'componentWeightageId',
  as: 'subComponents'
});

// SubComponents belongs to ComponentWeightage
SubComponents.belongsTo(ComponentWeightage, {
  foreignKey: 'componentWeightageId',
  as: 'componentWeightage'
});

// --- StudentMarks Associations ---

// Student has many StudentMarks
Student.hasMany(StudentMarks, {
  foreignKey: 'studentId',
  as: 'studentMarks'
});

// StudentMarks belongs to Student
StudentMarks.belongsTo(Student, {
  foreignKey: 'studentId',
  as: 'student'
});

// User (Faculty) has many StudentMarks
User.hasMany(StudentMarks, {
  foreignKey: 'facultyId',
  as: 'gradedMarks'
});

// StudentMarks belongs to User (Faculty)
StudentMarks.belongsTo(User, {
  foreignKey: 'facultyId',
  as: 'faculty'
});

// UniqueSubDegree has many StudentMarks
UniqueSubDegree.hasMany(StudentMarks, {
  foreignKey: 'subjectId',
  sourceKey: 'sub_code',
  as: 'studentMarks'
});

// StudentMarks belongs to UniqueSubDegree
StudentMarks.belongsTo(UniqueSubDegree, {
  foreignKey: 'subjectId',
  targetKey: 'sub_code',
  as: 'subject'
});

// Semester has many StudentMarks
Semester.hasMany(StudentMarks, {
  foreignKey: 'semesterId',
  as: 'studentMarks'
});

// StudentMarks belongs to Semester
StudentMarks.belongsTo(Semester, {
  foreignKey: 'semesterId',
  as: 'semester'
});

// Batch has many StudentMarks
Batch.hasMany(StudentMarks, {
  foreignKey: 'batchId',
  as: 'studentMarks'
});

// StudentMarks belongs to Batch
StudentMarks.belongsTo(Batch, {
  foreignKey: 'batchId',
  as: 'batch'
});

// SubComponents has many StudentMarks (for sub-component marks)
SubComponents.hasMany(StudentMarks, {
  foreignKey: 'subComponentId',
  as: 'studentMarks'
});

// StudentMarks belongs to SubComponents (optional, for sub-component marks)
StudentMarks.belongsTo(SubComponents, {
  foreignKey: 'subComponentId',
  as: 'subComponent'
});

// --- StudentBloomsDistribution Associations ---

// StudentBloomsDistribution belongs to Student
StudentBloomsDistribution.belongsTo(Student, {
  foreignKey: 'studentId',
  as: 'student'
});

// Student has many StudentBloomsDistribution
Student.hasMany(StudentBloomsDistribution, {
  foreignKey: 'studentId',
  as: 'bloomsDistributions'
});

// StudentBloomsDistribution belongs to UniqueSubDegree
StudentBloomsDistribution.belongsTo(UniqueSubDegree, {
  foreignKey: 'subjectId',
  targetKey: 'sub_code',
  as: 'subject'
});

// UniqueSubDegree has many StudentBloomsDistribution
UniqueSubDegree.hasMany(StudentBloomsDistribution, {
  foreignKey: 'subjectId',
  sourceKey: 'sub_code',
  as: 'bloomsDistributions'
});

// StudentBloomsDistribution belongs to BloomsTaxonomy
StudentBloomsDistribution.belongsTo(BloomsTaxonomy, {
  foreignKey: 'bloomsTaxonomyId',
  as: 'bloomsTaxonomy'
});

// BloomsTaxonomy has many StudentBloomsDistribution
BloomsTaxonomy.hasMany(StudentBloomsDistribution, {
  foreignKey: 'bloomsTaxonomyId',
  as: 'bloomsDistributions'
});

module.exports = {
  StudentPoints,
  EventMaster,
  ParticipationType,
  EventOutcomes,
  EventOutcomeMapping,
  UniqueSubDegree,
  CourseOutcome,
  ComponentWeightage,
  SubjectComponentCo,
  BloomsTaxonomy,
  CoBloomsTaxonomy,
  ClassSection,
  Semester,
  Batch,
  SubComponents,
  StudentMarks,
  Student,
  User,
  StudentBloomsDistribution
};
