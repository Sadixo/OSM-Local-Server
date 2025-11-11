FROM nginx:alpine

# Rimuovi configurazione di default
RUN rm /etc/nginx/conf.d/default.conf

# Copia configurazione custom
COPY conf/nginx-overpass-apikey.conf /etc/nginx/conf.d/

# Installa dipendenze necessarie
RUN apk add --no-cache \
    nginx-mod-http-headers-more \
    && mkdir -p /var/cache/nginx

# Script di inizializzazione
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nginx -t || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
