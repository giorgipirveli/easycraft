#!/usr/bin/env bash
# EasyCraft development server (Nakama + PostgreSQL in Docker). See server/README.md.
#   server/dev.sh up       build the TypeScript module, start both containers, wait until healthy
#   server/dev.sh reload   rebuild the module and restart Nakama (keeps the database)
#   server/dev.sh status   container state and health
#   server/dev.sh logs     follow Nakama's log (Ctrl+C stops following, not the server)
#   server/dev.sh down     stop and remove the containers; the database volume is kept
#   server/dev.sh reset    down, and delete the database volume (every account and match is gone)
#   server/dev.sh build    build the module only
# Always compose project "easycraft": other projects' containers on this PC are never touched.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
compose=(docker compose -f "$here/docker-compose.yml" -p easycraft)

build() {
	if [[ ! -d "$here/modules/node_modules" ]]; then
		npm --prefix "$here/modules" ci --no-audit --no-fund
	fi
	npm --prefix "$here/modules" run build
}

case "${1:-}" in
	up)     build; "${compose[@]}" up -d --wait ;;
	reload) build; "${compose[@]}" restart nakama ;;
	status) "${compose[@]}" ps ;;
	logs)   "${compose[@]}" logs -f nakama ;;
	down)   "${compose[@]}" down ;;
	reset)  "${compose[@]}" down -v ;;
	build)  build ;;
	*)      sed -n '2,10p' "$0"; exit 2 ;;
esac
