#!/bin/sh
set -e

if [ -f "$API_KEYS_FILE" ]; then

    # Processa ogni linea del file secrets
    while IFS= read -r line || [ -n "$line" ]; do
        # Salta linee vuote e commenti
        if [ -z "$line" ] || [ "$(echo "$line" | cut -c1)" = "#" ]; then
            continue
        fi

        # Rimuovi spazi e aggiungi alla mappa come "key" 1;
        key_clean=$(echo "$line" | tr -d '[:space:]')
        if [ ! -z "$key_clean" ]; then
            echo "\"$key_clean\" 1;" >> /etc/nginx/conf.d/api_keys.map
        fi
    done < "$API_KEYS_FILE"

    echo "Content preview:"
    head -n 5 /etc/nginx/conf.d/api_keys.map

    chmod 644 /etc/nginx/conf.d/api_keys.map
else
    echo "ERROR: Secrets file not found at $API_KEYS_FILE"
    exit 1
fi

exec "$@"