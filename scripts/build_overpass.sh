#!/bin/bash
set -e

VERSION=${1:-0.7.62.8}
INSTALL_DIR=/usr/local/overpass

cd /opt
wget -O - http://dev.overpass-api.de/releases/osm-3s_v${VERSION}.tar.gz | tar xz
cd /opt/osm-3s_v${VERSION}

./configure CXXFLAGS="-O2" --enable-lz4 --prefix=${INSTALL_DIR} && make install