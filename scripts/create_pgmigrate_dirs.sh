#!/bin/bash
# Имя базы и схемы задаются в файле config.sh со скриптом
# Через опцию `-p` можно задать папку, где будет создана структура
# иначе - создасться в директории со скриптом
# Например, чтобы создать в текущей директории: bash ../scripts/create_pgmigrate_dirs.sh -p `pwd`

set -e
set -u

ScriptDir="$(dirname "$0")"
WD="$(dirname "$0")"

source "${ScriptDir}/config.sh"

while getopts p: flag
do
    case "${flag}" in
        p) WD=${OPTARG};;
    esac
done

if [ -z ${DB+x} ]; then
    echo "Database is not defined"
    exit 1
fi

if [ -z ${SCHEMES+x} ]; then
    echo "Schemas is not defined"
    exit 1
fi

mkdir -v "$WD/${DB}"
for SCHEMA in "${SCHEMES[@]}"; do
	mkdir -v "${WD}/${DB}/${SCHEMA}"
        eval "cat <<EOF
$(<${ScriptDir}/t_migrations.tmpl)
EOF" >  "${WD}/${DB}/${SCHEMA}/migrations.yml"  2> /dev/null 

	mkdir -v "${WD}/${DB}/${SCHEMA}/migrations"
	mkdir -v "${WD}/${DB}/${SCHEMA}/callbacks"
	mkdir -v "${WD}/${DB}/${SCHEMA}/callbacks/beforeEach"
	mkdir -v "${WD}/${DB}/${SCHEMA}/callbacks/afterEach"

        eval "cat <<EOF
$(<${ScriptDir}/t_before_each.tmpl)
EOF" >  "${WD}/${DB}/${SCHEMA}/callbacks/beforeEach/00_before_each.sql"

        eval "cat <<EOF
$(<${ScriptDir}/t_after_each.tmpl)
EOF" >  "${WD}/${DB}/${SCHEMA}/callbacks/afterEach/00_after_each.sql"
done
