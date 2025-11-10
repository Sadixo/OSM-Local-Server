#!/bin/bash
set -e

DB_DIR=${1:-/usr/local/overpass_db}
OVERPASS_DIR=${2:-/usr/local/overpass}

chmod 755 ${OVERPASS_DIR}/bin/*.sh ${OVERPASS_DIR}/cgi-bin/*

# Se il DB non è inizializzato, esegui init al runtime
if [ ! -f ${DB_DIR}/replicate_id ] && [ ! -f ${DB_DIR}/nodes.map ]; then
  echo "[start] initializing database in ${DB_DIR}"
  /scripts/init_db.sh ${DB_DIR} ${PLANET_URL}
  echo "[start] initialization completed"
fi

# Clean up leftover sockets
rm -f ${DB_DIR}/osm3s_* || true
mkdir -p ${DB_DIR}

# Start dispatcher
${OVERPASS_DIR}/bin/dispatcher --osm-base --db-dir=${DB_DIR} --rate-limit=0 --allow-duplicate-queries=yes &
sleep 3
chmod 666 ${DB_DIR}/osm3s_osm_base

# non utilizzo fetch_osc_and_apply, visto che non applico cambiamenti globali, ho solo una mappa parziale
#echo "115276" > ${DB_DIR}/replicate_id
#${OVERPASS_DIR}/bin/fetch_osc_and_apply.sh "https://planet.openstreetmap.org/replication/hour/" &

# Start query server
${OVERPASS_DIR}/bin/osm3s_query --db-dir=${DB_DIR} &

# Avvia fcgiwrap sul socket usato da Nginx (con utente www-data)
/usr/sbin/fcgiwrap -s unix:/var/run/fcgiwrap.socket &
sleep 3
chown www-data:www-data /var/run/fcgiwrap.socket || true

# Avvia Nginx in foreground
exec nginx -g 'daemon off;'