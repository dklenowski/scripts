--
-- PAY ATTENTION!!
--
-- This query is freaking expensive. It holds the kernel_mutex while it's
-- running, so it can count items in the InnoDB Buffer Pool.
-- 
-- BEFORE YOU RUN IT IN PRODUCTION, THINK ABOUT THE CONSEQUENCES.
--
-- Also good to know: the percentile of the table in memory ("% IN MEMORY"
-- column) can go above 100%. This is because MySQL does copy-on-write.
-- If your table is just hot enough, you can probably see more than one copy of
-- the same page in memory at the same time, and this will show up in the "% IN
-- MEMORY" column, as you might expect.
--
SET SESSION SQL_MODE = "ANSI,ANSI_QUOTES,TRADITIONAL";
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT "schema"                         AS "SCHEMA"
     , innodb_sys_tables.name           AS "TABLE"
     , innodb_sys_indexes.name          AS "INDEX"
     , cnt                              AS "TOTAL PAGES"
     , dirty                            AS "DIRTY PAGES"
     , hashed                           AS "HASHED PAGES"
     , ROUND(cnt * 100 / index_size, 2) AS "% IN MEMORY"
FROM (
    SELECT index_id
         , COUNT(*)        cnt
         , SUM(dirty = 1)  dirty
         , SUM(hashed = 1) hashed
    FROM information_schema.innodb_buffer_pool_pages_index
    GROUP BY index_id
) AS bp
JOIN information_schema.innodb_sys_indexes ON id = index_id
JOIN information_schema.innodb_sys_tables  ON table_id = innodb_sys_tables.id
JOIN information_schema.innodb_index_stats ON
           innodb_index_stats.table_name = innodb_sys_tables.name
       AND innodb_sys_indexes.name = innodb_index_stats.index_name
       AND innodb_index_stats.table_schema = innodb_sys_tables.SCHEMA
WHERE innodb_sys_tables.name = 'keyword_counter'
ORDER  BY "TOTAL PAGES" DESC;
