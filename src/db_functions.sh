export MYSQL_PWD='{{secrets_mysql_root_pass}}'

function run_sql_from_file {
    mysql -u "{{secrets_mysql_root_user}}" < $1
}

function run_sql {
    mysql -u "{{secrets_mysql_root_user}}"
}

function run_sql_into_db {
    echo "CREATE DATABASE IF NOT EXISTS $1;" | run_sql
    mysql -u "{{secrets_mysql_root_user}}" $1 < $2
}
function force_run_sql_from_file {
    mysql -f -u "{{secrets_mysql_root_user}}" < $1
}

function database_exists_p {
    DB_QUERY_RESULTS="$(echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$1'" | mysql -u "{{secrets_mysql_root_user}}")"
    if [ -z "$DB_QUERY_RESULTS" ]
    then
	return 1
    else
	return 0
    fi
}
