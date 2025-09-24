-- Drop the existing table
DROP TABLE IF EXISTS subject_component_cos;

-- Recreate the table without the unique constraint
CREATE TABLE subject_component_cos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_component_id INT NOT NULL,
    course_outcome_id INT NOT NULL,
    component VARCHAR(10) NOT NULL COMMENT 'Component name (e.g., CA, ESE, IA, TW, VIVA)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_component_id) REFERENCES component_weightages(id),
    FOREIGN KEY (course_outcome_id) REFERENCES course_outcomes(id)
); 