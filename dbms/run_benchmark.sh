#!/usr/bin/env bash
# Execute CP4 workloads against an already initialised, seeded PostgreSQL database.
# Connection settings: PGHOST, PGPORT, PGUSER, PGPASSWORD/PGPASSFILE as for psql.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/benchmark.py" "${1:-kalpa_db}" "${2:-3}"
