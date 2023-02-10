#!/bin/bash

ScriptDir="$(dirname "$0")"
set -e
set -u

source "${ScriptDir}/config.sh"

if [ -z ${DB+x} ]; then
    echo "Database is not defined"
    exit 1
fi

if [ -z ${SCHEMES+x} ]; then
    echo "Schemas is not defined"
    exit 1
fi
# -X, --no-psqlrc
# -b, --echo-errors
# -1 ("one"), --single-transaction
export PGOPTIONS='--client-min-messages=warning'
PSQL="psql -X -q -e -1 --set ON_ERROR_STOP=on -d $DB"
PSQL_RUN="${PSQL}"

#######################################
# Check and create role with roles
# Globals:
#   PSQL_RUN
# Arguments:
#   role name, roles
# Returns:
#   0 if thing was deleted, non-zero on error.
#######################################
function create_role() {
	local username="$1"
	local roles="$2"
	
	$PSQL_RUN<<SQL 1>/dev/null
do
\$\$
begin
  if not exists (select * from pg_roles where rolname = '${username}') then
     create role ${username};
  end if;
  alter role ${username} $roles;
end
\$\$
SQL
}


for schema in "${SCHEMES[@]}"; do
    DB_SCHEMA="${DB}_${schema}"
	echo "Schema: ${DB_SCHEMA}"
	${PSQL} -q -c "CREATE SCHEMA IF NOT EXISTS ${schema}" >/dev/null
        # Роль/группа для чтения в схеме
	create_role "${DB_SCHEMA}_view" "NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOLOGIN"
	create_role "${DB_SCHEMA}_write" "NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOLOGIN"
	# Роль доступна только через set role. Напрямую пользователям не назначается
	create_role "${DB_SCHEMA}_owner" "NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOLOGIN"
	# Роль позволяющая сделать set role *_owner. Сама по себе на дает прав owner т.к. noinherit
	create_role "${DB_SCHEMA}_sudo" "NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOLOGIN"
	# Роль *_owner так же может управлять членством в группах _view и _write
	${PSQL} -c "GRANT ${DB_SCHEMA}_view,${DB_SCHEMA}_write TO ${DB_SCHEMA}_owner"
	${PSQL} -c "GRANT ${DB_SCHEMA}_view TO ${DB_SCHEMA}_sudo"
	${PSQL} -c "GRANT ${DB_SCHEMA}_owner TO ${DB_SCHEMA}_sudo"
	${PSQL} -c "GRANT CONNECT ON DATABASE ${DB} TO ${DB_SCHEMA}_view"
	${PSQL} -c "GRANT ${DB_SCHEMA}_view TO ${DB_SCHEMA}_write"
	${PSQL} -c "GRANT usage ON SCHEMA ${schema} TO ${DB_SCHEMA}_view"
	${PSQL} -c "GRANT ALL ON SCHEMA ${schema} TO ${DB_SCHEMA}_owner"
	${PSQL} -c "GRANT ALL ON SCHEMA ${schema} TO ${DB_SCHEMA}_sudo"
	${PSQL} -c "ALTER DEFAULT PRIVILEGES FOR ROLE ${DB_SCHEMA}_owner IN SCHEMA ${schema} GRANT SELECT ON SEQUENCES TO ${DB_SCHEMA}_view"
        ${PSQL} -c "ALTER DEFAULT PRIVILEGES FOR ROLE ${DB_SCHEMA}_owner IN SCHEMA ${schema} GRANT SELECT ON TABLES TO ${DB_SCHEMA}_view"
	${PSQL} -c "ALTER DEFAULT PRIVILEGES FOR ROLE ${DB_SCHEMA}_owner IN SCHEMA ${schema} GRANT ALL ON SEQUENCES TO ${DB_SCHEMA}_write"
	${PSQL} -c "ALTER DEFAULT PRIVILEGES FOR ROLE ${DB_SCHEMA}_owner IN SCHEMA ${schema} GRANT EXECUTE ON FUNCTIONS TO ${DB_SCHEMA}_write"
	${PSQL} -c "ALTER DEFAULT PRIVILEGES FOR ROLE ${DB_SCHEMA}_owner IN SCHEMA ${schema} GRANT INSERT,UPDATE,DELETE,TRUNCATE ON TABLES TO ${DB_SCHEMA}_write"
        
        ## Apply to exist object
	#${PSQL} -c "GRANT INSERT,UPDATE,DELETE,TRUNCATE ON ALL TABLES IN SCHEMA ${schema} TO ${DB_SCHEMA}_write;"
	#${PSQL} -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA ${schema} TO ${DB_SCHEMA}_write;"
        ## For pgmigrate
	#${PSQL} -c "REVOKE ALL ON TABLE ${schema}.schema_version FROM ${DB_SCHEMA}_write;"
done
