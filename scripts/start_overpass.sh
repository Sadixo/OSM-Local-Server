#!/bin/bash
set -e

DB_DIR=${1:-/usr/local/overpass_db}
OVERPASS_DIR=${2:-/usr/local/overpass}

# Handler di shutdown per SIGTERM/SIGINT
cleanup() {
  echo "[shutdown] terminating dispatcher"
  ${OVERPASS_DIR}/bin/dispatcher --terminate || true
  echo "[shutdown] cleaning sockets"
  rm -f ${DB_DIR}/osm3s_* || true
  # termina processi ausiliari se ancora vivi
  [ -n "${FCGI_PID:-}" ] && kill -TERM "$FCGI_PID" 2>/dev/null || true
  [ -n "${CRON_PID:-}" ] && service cron stop 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT

chmod 700 ${OVERPASS_DIR}/bin/*.sh ${OVERPASS_DIR}/cgi-bin/*

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
DISPATCHER_PID=$!
sleep 3

# non utilizzo fetch_osc_and_apply, visto che non applico cambiamenti globali, ho solo una mappa parziale
#echo "115276" > ${DB_DIR}/replicate_id
#${OVERPASS_DIR}/bin/fetch_osc_and_apply.sh "https://planet.openstreetmap.org/replication/hour/" &

# Start query server
${OVERPASS_DIR}/bin/osm3s_query --db-dir=${DB_DIR} &

# Avvia fcgiwrap sul socket usato da Nginx (con utente www-data)
/usr/sbin/fcgiwrap -s tcp:0.0.0.0:9000 &
FCGI_PID=$!

# Avvio di cron per l'update
echo "0 1 * * 7 root /scripts/update_db.sh >> /var/log/overpass_update.log 2>&1; tail -c 102400 /var/log/overpass_update.log > /var/log/overpass_update.log.tmp && mv /var/log/overpass_update.log.tmp /var/log/overpass_update.log" > /etc/cron.d/overpass-update
chmod 0644 /etc/cron.d/overpass-update
service cron start

CRON_PID=$!

wait $DISPATCHER_PID $FCGI_PID $CRON_PID || true
cleanup
