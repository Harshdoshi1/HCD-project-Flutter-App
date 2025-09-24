# Weighted Marks Distribution System

## Overview
This document describes the implementation of the automatic weighted marks distribution system that converts student's scored marks into weighted marks and distributes them to Course Outcomes (COs) and Bloom's Taxonomy levels.

## Key Features

### 1. Automatic Weighted Marks Calculation
- Each component/subcomponent has a specific weightage percentage
- Total subject marks are fixed at 150
- Formula: `Weighted Marks = (Marks Obtained / Total Marks) × (Weightage% × 150)`

### 2. CO and Bloom's Taxonomy Mapping
- Each component/subcomponent is mapped to one or more Course Outcomes (COs)
- Each CO is linked to specific Bloom's Taxonomy levels (Remember, Understand, Apply, Analyze, Evaluate, Create)
- Weighted marks are distributed to all associated COs and their Bloom's levels

### 3. Automatic Processing
- When faculty assigns grades to any component/subcomponent, the system automatically:
  1. Calculates weighted marks based on weightage
  2. Maps marks to associated COs
  3. Distributes marks to Bloom's Taxonomy levels
  4. Stores the distribution in the database

## Implementation Details

### Files Created/Modified

#### 1. **`backend/utils/marksDistributionHelper.js`** (NEW)
Core utility module containing:
- `calculateWeightedMarks()` - Calculates weighted marks for components
- `getCOsAndBloomsMapping()` - Retrieves CO and Bloom's level mappings
- `calculateAndDistributeMarks()` - Main distribution logic
- `processStudentMarksDistribution()` - Entry point for processing

#### 2. **`backend/controller/bloomsAnalysisController.js`** (NEW)
Analysis and reporting endpoints:
- `getDetailedBloomsAchievement()` - Detailed student achievement report
- `compareBloomsAchievement()` - Batch-wise comparison
- `getCOAttainmentReport()` - CO attainment analysis

#### 3. **`backend/routes/bloomsAnalysis_routes.js`** (NEW)
API routes for analysis endpoints

#### 4. **`backend/controller/bloomsDistributionController.js`** (MODIFIED)
Updated to use weighted marks calculation logic

#### 5. **`backend/controller/studentMarksController.js`** (MODIFIED)
Triggers automatic distribution when marks are updated

#### 6. **`backend/models/StudentBloomsDistribution.js`** (MODIFIED)
Updated schema to store weighted marks and component mapping

## API Endpoints

### 1. Calculate and Store Distribution
```
POST /api/blooms-taxonomy/calculate/:enrollmentNumber/:semesterNumber
```
Calculates and stores weighted marks distribution for a student

### 2. Get Detailed Achievement
```
GET /api/blooms-analysis/student/:enrollmentNumber/semester/:semesterNumber
GET /api/blooms-analysis/student/:enrollmentNumber/semester/:semesterNumber/subject/:subjectId
```
Returns detailed breakdown of student's achievement by COs and Bloom's levels

### 3. Compare Batch Achievement
```
GET /api/blooms-analysis/compare/batch/:batchId/semester/:semesterNumber
GET /api/blooms-analysis/compare/batch/:batchId/semester/:semesterNumber/subject/:subjectId
```
Compares Bloom's achievement across all students in a batch

### 4. CO Attainment Report
```
GET /api/blooms-analysis/co-attainment/subject/:subjectId/batch/:batchId/semester/:semesterNumber
```
Generates CO attainment report showing percentage of students meeting threshold

## Example Workflow

### Scenario: Quiz Component with 30 marks and 10% weightage

1. **Component Configuration**:
   - Quiz: 30 total marks, 10% weightage
   - Mapped to CO1 and CO2
   - CO1 → Remember, Analyze
   - CO2 → Apply

2. **Student Scores**: 25/30 marks

3. **Automatic Calculation**:
   - Allocated marks for quiz = 10% × 150 = 15 marks
   - Weighted marks = (25/30) × 15 = 12.5 marks

4. **Distribution**:
   - Remember: +12.5 marks
   - Analyze: +12.5 marks
   - Apply: +12.5 marks
   - Each Bloom's level receives the full weighted marks

5. **Storage**: All distributions stored in `StudentBloomsDistribution` table

## Database Schema

### StudentBloomsDistribution Table
```sql
{
  studentId: INTEGER,
  semesterNumber: INTEGER,
  subjectId: STRING,
  studentMarksSubjectComponentId: INTEGER,
  totalMarksOfComponent: DECIMAL,
  subComponentWeightage: DECIMAL,
  selectedCOs: JSON,
  courseOutcomeId: INTEGER,
  bloomsTaxonomyId: INTEGER,
  assignedMarks: DECIMAL,
  calculatedAt: DATE
}
```

## Benefits

1. **Automated Processing**: No manual calculation required
2. **Accurate Distribution**: Precise weighted marks calculation
3. **Comprehensive Tracking**: Maps to both COs and Bloom's levels
4. **Real-time Updates**: Instant calculation when marks are entered
5. **Detailed Analytics**: Multiple report types for analysis
6. **Scalable**: Handles components and subcomponents seamlessly

## Testing

To test the implementation:

1. Create a subject with components and weightages
2. Map components to COs
3. Link COs to Bloom's Taxonomy levels
4. Enter student marks
5. Check the automatic distribution using the analysis APIs

## Future Enhancements

1. Visualization dashboards for Bloom's achievement
2. Export reports to PDF/Excel
3. Batch processing for bulk mark uploads
4. Configurable weightage formulas
5. Historical trend analysis
