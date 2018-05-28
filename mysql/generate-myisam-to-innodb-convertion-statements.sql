-- Convert all MyISAM tables in all databases to InnoDB
--
-- This query generates the queries required to convert all tables in MyISAM to
-- the InnoDB (except for the tables that are under the "mysql" and
-- "information_schema" tables, which are not supposed to be InnoDB).
-- 
-- To generate the queries for the change you can call /usr/bin/mysql like this:
--
--     mysql --quick --BNsD information_schema \
--         < generate-myisam-to-innodb-convertion-statements.sql \
--         > myisam-to-innodb.sql
--
-- After generating the queries you can apply it to production with
--
--     mysql -tvv < myisam-to-innodb.sql > myisam-to-innodb.log
--

SET SESSION SQL_MODE="ANSI,ANSI_QUOTES";
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Session sql-mode settings
SELECT 'SET SESSION SQL_MODE="ANSI,ANSI_QUOTES";';

-- InnoDB Migration Statements
SELECT CONCAT(
  'ALTER TABLE "', TABLE_SCHEMA, '"."', TABLE_NAME, '" ENGINE=InnoDB;'
) AS "SQL CODE"
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA NOT IN ( 'mysql', 'information_schema')
  AND ENGINE = 'MyISAM'
ORDER BY DATA_LENGTH;
