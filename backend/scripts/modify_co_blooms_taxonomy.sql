-- Drop existing indexes
ALTER TABLE co_blooms_taxonomy DROP INDEX co_blooms_unique;

-- Drop the table and recreate it without the unique constraint
DROP TABLE IF EXISTS co_blooms_taxonomy;

CREATE TABLE co_blooms_taxonomy (
    course_outcome_id INT NOT NULL,
    blooms_taxonomy_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (course_outcome_id, blooms_taxonomy_id),
    FOREIGN KEY (course_outcome_id) REFERENCES course_outcomes(id) ON DELETE CASCADE,
    FOREIGN KEY (blooms_taxonomy_id) REFERENCES blooms_taxonomy(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 