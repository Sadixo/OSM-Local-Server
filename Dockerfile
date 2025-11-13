FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OVERPASS_VERSION=0.7.62.8 \
    DB_DIR=/usr/local/overpass_db \
    OVERPASS_DIR=/usr/local/overpass \
    PLANET_URL=https://download.geofabrik.de/europe/italy-latest.osm.pbf

RUN apt-get update && apt-get install -y \
    build-essential wget curl ca-certificates git \
    libexpat1-dev zlib1g-dev liblz4-dev liblzma-dev libxml2-dev \
    fcgiwrap cron \
    osmctools gzip \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh \
     && /scripts/build_overpass.sh ${OVERPASS_VERSION} \
     && chmod +x /opt/osm-3s_v${OVERPASS_VERSION}/bin/init_osm3s.sh

CMD ["/scripts/start_overpass.sh"]
