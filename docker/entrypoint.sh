#!/bin/sh
set -eu

# The init service writes the key once; all PHP services share this volume.
if [ -z "${APP_KEY:-}" ]; then
    if [ "${1:-}" = "initialize" ] && [ ! -s storage/app/key ]; then
        umask 077
        php -r 'echo "base64:".base64_encode(random_bytes(32));' > storage/app/key
    fi
    if [ ! -s storage/app/key ]; then
        echo 'Application key missing; run the init service first.' >&2
        exit 1
    fi
    APP_KEY=$(cat storage/app/key)
    export APP_KEY
fi

if [ "${1:-}" = "initialize" ]; then
    php artisan migrate --force --no-interaction
    exit 0
fi

exec "$@"
