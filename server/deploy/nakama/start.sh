#!/bin/sh
# Starts EasyCraft's Nakama on the internet (the image's entrypoint, see Dockerfile).
# 1. Refuses to start while a secret from .env is missing, too short, still a placeholder or one of
#    Nakama's defaults (docker-compose.yml passes them in as environment variables).
# 2. Writes them into a config file in memory (/run/easycraft is a tmpfs), so no secret is on the
#    command line or on disk.
# 3. Brings the database schema up to date (safe to repeat), then runs Nakama with production.yml
#    and that file. Extra arguments are passed on to Nakama (e.g. --logger.level DEBUG).
set -euf

secrets_dir=/run/easycraft
secrets="$secrets_dir/secrets.yml"
problems=0

refuse() {
	echo "start: $1" >&2
	problems=$((problems + 1))
}

# check NAME MIN_LENGTH: set, long enough, letters/digits/. _ ~ - only, not a placeholder or default.
check() {
	value=""
	eval "value=\${$1:-}"
	case "$value" in
		"")
			refuse "$1 is empty in .env (./kit.sh keys fills in every secret)"; return ;;
		*[!A-Za-z0-9._~-]*)
			refuse "$1 may only have letters, digits and . _ ~ -"; return ;;
		change-me* | CHANGE-ME* | CHANGE_ME* | defaultkey | defaulthttpkey | defaultencryptionkey | \
		defaultrefreshencryptionkey | defaultsigningkey | password | admin)
			refuse "$1 still has a placeholder or Nakama's default value"; return ;;
	esac
	if [ "${#value}" -lt "$2" ]; then
		refuse "$1 is shorter than $2 characters"
	fi
}

check NAKAMA_SERVER_KEY 16
check POSTGRES_PASSWORD 24
check NAKAMA_SESSION_ENCRYPTION_KEY 32
check NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY 32
check NAKAMA_CONSOLE_USERNAME 3
check NAKAMA_CONSOLE_PASSWORD 16
check NAKAMA_CONSOLE_SIGNING_KEY 32
check NAKAMA_RUNTIME_HTTP_KEY 32
if [ "${NAKAMA_SESSION_ENCRYPTION_KEY:-}" = "${NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY:-}" ]; then
	refuse "the two session encryption keys must differ"
fi

# EASYCRAFT_RUNTIME_ENV: "KEY=value KEY2=value2" for the server module (ctx.env), e.g. a consent
# provider's settings. EASYCRAFT_ENV=production is always there.
runtime_env='    - "EASYCRAFT_ENV=production"'
for pair in ${EASYCRAFT_RUNTIME_ENV:-}; do
	case "$pair" in
		*\"* | *\\*)
			refuse "EASYCRAFT_RUNTIME_ENV: no quotes or backslashes in $pair" ;;
		[A-Za-z_]*=*)
			runtime_env="$runtime_env
    - \"$pair\"" ;;
		*)
			refuse "EASYCRAFT_RUNTIME_ENV: '$pair' is not KEY=value" ;;
	esac
done

if [ "$problems" -gt 0 ]; then
	echo "start: not starting: fix .env, then ./kit.sh up (docs/hosting.md)" >&2
	exit 78
fi

umask 077
mkdir -p "$secrets_dir"
cat > "$secrets" <<EOF
database:
  address:
    - "nakama:${POSTGRES_PASSWORD}@postgres:5432/nakama"
socket:
  server_key: "${NAKAMA_SERVER_KEY}"
session:
  encryption_key: "${NAKAMA_SESSION_ENCRYPTION_KEY}"
  refresh_encryption_key: "${NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY}"
console:
  username: "${NAKAMA_CONSOLE_USERNAME}"
  password: "${NAKAMA_CONSOLE_PASSWORD}"
  signing_key: "${NAKAMA_CONSOLE_SIGNING_KEY}"
runtime:
  http_key: "${NAKAMA_RUNTIME_HTTP_KEY}"
  env:
${runtime_env}
EOF

echo "start: settings checked; updating the database schema"
/nakama/nakama migrate up --config "$secrets"
echo "start: starting Nakama"
exec /nakama/nakama --config /nakama/data/production.yml --config "$secrets" "$@"
