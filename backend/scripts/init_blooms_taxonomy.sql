-- Drop existing tables if they exist
DROP TABLE IF EXISTS co_blooms_taxonomy;
DROP TABLE IF EXISTS blooms_taxonomy;

-- Create blooms_taxonomy table
CREATE TABLE blooms_taxonomy (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create co_blooms_taxonomy table with composite primary key
CREATE TABLE co_blooms_taxonomy (
    course_outcome_id INT NOT NULL,
    blooms_taxonomy_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (course_outcome_id, blooms_taxonomy_id),
    FOREIGN KEY (course_outcome_id) REFERENCES course_outcomes(id) ON DELETE CASCADE,
    FOREIGN KEY (blooms_taxonomy_id) REFERENCES blooms_taxonomy(id) ON DELETE CASCADE
);

-- Insert default Blooms Taxonomy levels
INSERT INTO blooms_taxonomy (name, description) VALUES
('Remember', 'Recall facts and basic concepts'),
('Understand', 'Explain ideas or concepts'),
('Apply', 'Use information in new situations'),
('Analyze', 'Draw connections among ideas'),
('Evaluate', 'Justify a stand or decision'),
('Create', 'Produce new or original work'); 