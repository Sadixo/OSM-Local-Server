set -euo pipefail

DB_DIR=${1:-/usr/local/overpass_db}
PLANET_URL=${2:-https://download.geofabrik.de/europe/italy-latest.osm.pbf}
OVERPASS_DIR=/usr/local/overpass
PLANET_PBF=italy-latest.osm.pbf
PLANET_GZ=italy-latest.osm.gz
#PLANET_PBF=monaco-latest.osm.pbf
#PLANET_GZ=monaco-latest.osm.gz

echo "Terminating dispatcher"
${OVERPASS_DIR}/bin/dispatcher --terminate
rm -f ${DB_DIR}/osm3s_* || true

echo "[update] downloading latest PBF"

mkdir -p ${DB_DIR}
cd ${DB_DIR}
wget ${PLANET_URL}
osmconvert ${DB_DIR}/${PLANET_PBF} | gzip -1 >${PLANET_GZ}

#${OVERPASS_DIR}/bin/init_osm3s.sh ${DB_DIR}/${PLANET_PBF} ${DB_DIR} ${OVERPASS_DIR}

gunzip <${DB_DIR}/${PLANET_GZ} | ${OVERPASS_DIR}/bin/update_database --db-dir=${DB_DIR}
rm -f ${PLANET_PBF} ${PLANET_GZ}

echo "[update] done. Restart of the dispatcher"

${OVERPASS_DIR}/bin/dispatcher --osm-base --db-dir=${DB_DIR} --rate-limit=0 --allow-duplicate-queries=yes &
sleep 3
chmod 666 ${DB_DIR}/osm3s_osm_base

# non utilizzo fetch_osc_and_apply, visto che non applico cambiamenti globali, ho solo una mappa parziale
#echo "115276" > ${DB_DIR}/replicate_id
#${OVERPASS_DIR}/bin/fetch_osc_and_apply.sh "https://planet.openstreetmap.org/replication/hour/" &

# Start query server
#${OVERPASS_DIR}/bin/osm3s_query --db-dir=${DB_DIR} &
