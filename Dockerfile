ARG MARIADB_VERSION="10.11"

FROM ghcr.io/n0rthernl1ghts/mariadb:${MARIADB_VERSION} AS mariadb
FROM mariadb AS mariadb-overlay

RUN set -eux \
    && rm -rf /etc/s6-overlay/s6-rc.d/init-config-end/dependencies.d/init-mariadb-initdb \
              /etc/s6-overlay/s6-rc.d/init-mariadb-* \
              /etc/s6-overlay/s6-rc.d/init-fix-permissions \
              /etc/s6-overlay/s6-rc.d/svc-mariadb \
              /etc/s6-overlay/s6-rc.d/user/contents.d/init-mariadb-* \
              /etc/s6-overlay/s6-rc.d/user/contents.d/init-fix-permissions \
              /etc/s6-overlay/s6-rc.d/user/contents.d/svc-mariadb \
              /usr/local/bin/gomplate \
    && apk del mariadb mariadb-server-utils mariadb-client




FROM scratch AS rootfs

COPY --from=mariadb-overlay ["/", "/"]
COPY ["./src/", "/app/"]
COPY ["./rootfs/", "/"]



FROM scratch

COPY --from=rootfs ["/", "/"]

ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
  HOME="/root" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-mods \
  VIRTUAL_ENV=/lsiopy \
  PATH="/lsiopy/bin:$PATH" \
  MYSQL_DIR="/config" \
  DATADIR="/var/lib/mysql" \
  BACKUP_LIMIT=5 \
  BACKUP_DIR="/config/backup" \
  BACKUP_METADATA_DIR="/config/backup-metadata" \
  BACKUP_PROCESS_LIMIT=10 \
  HOUSEKEEPER_PROCESS_LIMIT=10 \
  CRONTAB_EXPRESSION="0 0 * * *"

ARG MARIADB_VERSION
LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>" \
      org.opencontainers.image.source="https://github.com/N0rthernL1ghts/mariadb-backup" \
      org.opencontainers.image.description="MariaDB Backup Companion ${MARIADB_VERSION} (${TARGETPLATFORM})" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${MARIADB_VERSION}"

ENV MARIADB_VERSION="${MARIADB_VERSION}"

ENTRYPOINT ["/init"]
