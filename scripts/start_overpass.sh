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

# Apache vhost enable
a2enmod cgi ext_filter
a2ensite overpass.conf
a2dissite 000-default.conf || true
# Set a global ServerName to silence FQDN warning
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername
apachectl -t

# Start dispatcher
${OVERPASS_DIR}/bin/dispatcher --osm-base --db-dir=${DB_DIR} &
sleep 3
chmod 666 ${DB_DIR}/osm3s_osm_base

# non utilizzo fetch_osc_and_apply, visto che non applico cambiamenti globali, ho solo una mappa parziale
#echo "115276" > ${DB_DIR}/replicate_id
#${OVERPASS_DIR}/bin/fetch_osc_and_apply.sh "https://planet.openstreetmap.org/replication/hour/" &

# Start query server
${OVERPASS_DIR}/bin/osm3s_query --db-dir=${DB_DIR} &

# Run Apache in foreground
exec apachectl -D FOREGROUND
