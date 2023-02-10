#!/bin/bash

set -e
set -u

ScriptDir="$(dirname "$0")"

source "${ScriptDir}/config.sh"

for SCHEMA in "${SCHEMES[@]}"; do
   ( set -x; pgmigrate -d /opt/migrations/dwh/${SCHEMA} -v -m ${SCHEMA} --check_serial_versions -t latest migrate )
done
