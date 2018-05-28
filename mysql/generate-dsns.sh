#!/bin/bash
MASTER_DATABASE_VIP=$1
 
function mysql_query (){
    local DATABASE_HOST=$1
    local QUERY=$2
    /usr/bin/mysql -BNsh $DATABASE_HOST -e "$QUERY" 2>/dev/null
}
 
function generate_inserts (){
    local MASTER=$1
    local MASTER_SERVER_ID=$(mysql_query "$MASTER" 'SELECT @@server_id')
    mysql_query "$MASTER" "SELECT host FROM INFORMATION_SCHEMA.PROCESSLIST WHERE COMMAND = 'BINLOG DUMP' " |
        awk -F: '{print $1}' |
            while read h ; do
                #local H=$(dig +short "$h")
                local H=$(dig +noall +answer -x $h | awk '{print $5}'  |  cut -d"." -f1)
                local MYSQL_SERVER_ID=$(mysql_query "$h" 'SELECT @@server_id')
                if [ -n "$h" -a -n "$MYSQL_SERVER_ID" -a -n "$MASTER_SERVER_ID" ] && [ "$MYSQL_SERVER_ID" -gt 0 ] && [ "$MASTER_SERVER_ID" -gt 0 ]; then
                    echo "    INSERT INTO dsns( id, parent_id, dsn ) VALUES ( $MYSQL_SERVER_ID, $MASTER_SERVER_ID, '$H' );"
                fi
            done
}
function generate_transaction (){
    local MASTER=$1
    echo "CREATE DATABASE IF NOT EXISTS ecg_dba DEFAULT CHARACTER SET utf8;"
    echo -e "USE ecg_dba;\n"
    echo -ne "DROP TABLE IF EXISTS  dsns;\n\nCREATE TABLE IF NOT EXISTS dsns (\n"
    echo -ne "      id         INTEGER          NOT NULL AUTO_INCREMENT\n     , parent_id INTEGER      DEFAULT NULL\n"
    echo -ne "    , dsn        VARCHAR(255)     NOT NULL\n    , PRIMARY KEY( id )\n) ENGINE=InnoDB;\n\n"
    echo -e "START TRANSACTION;\n"
    echo -e "    DELETE FROM dsns;\n"
    generate_inserts "$MASTER"
    echo -e "\nCOMMIT;\n\n"
}
 
generate_transaction "$MASTER_DATABASE_VIP"

