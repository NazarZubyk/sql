#!/usr/bin/env bash
# Exports the current schema (DDL only) of the taxi database
# from the spp-mysql container into practice/ddl/taxi_schema_<timestamp>.sql
# so successive exports never overwrite each other.
#
# Usage: ./export_schema.sh   (run from anywhere; paths are script-relative)

set -euo pipefail

cd "$(dirname "$0")"

OUT_DIR="../practice/ddl"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT_FILE="${OUT_DIR}/taxi_schema_${STAMP}.sql"

if [ ! -f .env ]; then
    echo "error: .env not found in $(pwd) (see .env.example)" >&2
    exit 1
fi
# shellcheck disable=SC1091
source .env

docker exec spp-mysql mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" \
    --no-data --routines --set-gtid-purged=OFF --databases taxi > "$OUT_FILE"

echo "Schema written to $(cd "$OUT_DIR" && pwd)/taxi_schema_${STAMP}.sql"
