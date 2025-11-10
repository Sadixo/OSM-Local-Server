FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OVERPASS_VERSION=0.7.62.8 \
    DB_DIR=/usr/local/overpass_db \
    OVERPASS_DIR=/usr/local/overpass \
    PLANET_URL=https://download.geofabrik.de/europe/monaco-latest.osm.pbf

RUN apt-get update && apt-get install -y \
    build-essential wget curl ca-certificates git \
    libexpat1-dev zlib1g-dev liblz4-dev liblzma-dev libxml2-dev \
    nginx fcgiwrap \
    osmctools gzip \
#    osmosis\
    && rm -rf /var/lib/apt/lists/*

COPY scripts/ /scripts/
COPY conf/nginx-overpass.conf /etc/nginx/sites-available/overpass.conf
RUN chmod +x /scripts/*.sh \
     && /scripts/build_overpass.sh ${OVERPASS_VERSION} \
     && chmod +x /opt/osm-3s_v${OVERPASS_VERSION}/bin/init_osm3s.sh \
     && ln -sf /etc/nginx/sites-available/overpass.conf /etc/nginx/sites-enabled/overpass.conf \
     && rm -f /etc/nginx/sites-enabled/default

EXPOSE 80
CMD ["/scripts/start_overpass.sh"]
