USE INFORMATION_SCHEMA;

SELECT CONCAT( '/* Drop indexes from ', TABLE_SCHEMA, '.', TABLE_NAME, "*/\n",
               'ALTER TABLE ', TABLE_SCHEMA, '.', TABLE_NAME, "\n      ",
               GROUP_CONCAT( DISTINCT
                   CONCAT( 'DROP INDEX ', INDEX_SCHEMA, '.', INDEX_NAME ) SEPARATOR "\n    , "
               ), ";\nSHOW WARNINGS;\nSHOW ERRORS;\n"
       ) AS "SQL"
FROM information_schema.statistics
WHERE TABLE_SCHEMA NOT IN ('mysql', 'information_schema' )
  AND INDEX_NAME NOT IN ( 'PRIMARY' )
GROUP BY TABLE_SCHEMA, TABLE_NAME;
