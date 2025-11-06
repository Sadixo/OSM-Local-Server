#!/bin/bash
set -e

DB_DIR=${1:-/usr/local/overpass_db}
PLANET_URL=${2:-https://download.geofabrik.de/europe/italy-latest.osm.pbf}
OVERPASS_DIR=/usr/local/overpass
#PLANET_PBF=italy-latest.osm.pbf
#PLANET_GZ=italy-latest.osm.gz
PLANET_PBF=monaco-latest.osm.pbf
PLANET_GZ=monaco-latest.osm.gz

mkdir -p ${DB_DIR}
cd ${DB_DIR}
if [ ! -f ${PLANET_GZ} ]; then
  wget ${PLANET_URL}
  osmconvert ${DB_DIR}/${PLANET_PBF} | gzip -1 >${PLANET_GZ}
fi
#${OVERPASS_DIR}/bin/init_osm3s.sh ${DB_DIR}/${PLANET_PBF} ${DB_DIR} ${OVERPASS_DIR}

gunzip <${DB_DIR}/${PLANET_GZ} | ${OVERPASS_DIR}/bin/update_database --db-dir=${DB_DIR}
rm -f ${PLANET_PBF} ${PLANET_GZ}

#osmosis --read-pbf file=${DB_DIR}/${PLANET_PBF} --write-xml - | ${OVERPASS_DIR}/bin/update_database --db-dir=${DB_DIR}
#rm -f ${PLANET_PBF}
