SELECT /* Column Cardinality Calculation Meta SQL */
    CONCAT(
        'SELECT /* Cardinality Calculation for table "', TABLE_SCHEMA, '.', TABLE_NAME, '" */ ',
        GROUP_CONCAT( "\n      ", 'COUNT( ', COLUMN_NAME, ' ) / COUNT(*) AS "O( ', COLUMN_NAME, ' )"' ),
        '\nFROM ', TABLE_SCHEMA, '.', TABLE_NAME, '\\G'
    )
FROM COLUMNS
WHERE TABLE_SCHEMA=?
  AND TABLE_NAME=?
ORDER BY ORDINAL_POSITION
