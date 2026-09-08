# syntax=docker/dockerfile:1.7
#
# Build Asterisk from official sources (reproducible, version-pinned).
# Unraid labels + default configs are the "product" layer on top.
#
#   docker build \
#     --build-arg ASTERISK_VERSION="$(cat VERSION)" \
#     --build-arg ASTERISK_SHA256="$(tr -d '[:space:]' < ASTERISK_SHA256)" \
#     --build-arg VERSION=dev \
#     -t asterisk:dev .
#
# All four ASTERISK_*/VERSION build-args are REQUIRED — the Dockerfile
# intentionally defines no defaults so nothing silently builds an old version.

ARG DEBIAN_VERSION=bookworm

# ---------------------------------------------------------------------------
# Builder
# ---------------------------------------------------------------------------
FROM debian:${DEBIAN_VERSION}-slim AS builder

ARG ASTERISK_VERSION
ARG ASTERISK_SHA256
ARG ASTERISK_JOBS=0
ENV ASTERISK_VERSION=${ASTERISK_VERSION} \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    pkg-config \
    python3 \
    libedit-dev \
    libjansson-dev \
    libsqlite3-dev \
    uuid-dev \
    libxml2-dev \
    libxslt1-dev \
    libssl-dev \
    libncurses5-dev \
    libnewt-dev \
    libspandsp-dev \
    libopus-dev \
    libopusfile-dev \
    libsrtp2-dev \
    libvpx-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libvorbis-dev \
    libogg-dev \
    libcurl4-openssl-dev \
    libiksemel-dev \
    libsnmp-dev \
    libcap-dev \
    libsnmp-base \
    binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Official release tarball — reproducible OSS builds with SHA-256 verification.
RUN test -n "${ASTERISK_VERSION}" || (echo "ASTERISK_VERSION build-arg is required" >&2; exit 1) \
 && test -n "${ASTERISK_SHA256}" || (echo "ASTERISK_SHA256 build-arg is required" >&2; exit 1) \
 && curl -fsSL \
      "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz" \
      -o asterisk.tar.gz \
 && echo "${ASTERISK_SHA256}  asterisk.tar.gz" | sha256sum -c - \
 && tar xzf asterisk.tar.gz \
 && mv "asterisk-${ASTERISK_VERSION}" asterisk \
 && rm asterisk.tar.gz

WORKDIR /usr/src/asterisk

COPY build/menuselect-config.sh /usr/local/bin/menuselect-config.sh
RUN chmod +x /usr/local/bin/menuselect-config.sh

RUN ./configure \
      --with-jansson-bundled \
      --with-pjproject-bundled \
      --with-libedit \
      --with-ssl \
      --with-srtp \
      --with-crypto \
      --with-opus \
      --without-dahdi \
      --without-pri \
      --without-gtk2 \
      --without-radius \
      --without-gmime \
 && make menuselect.makeopts \
 && /usr/local/bin/menuselect-config.sh menuselect.makeopts \
 && JOBS="${ASTERISK_JOBS}" \
 && if [ "$JOBS" = "0" ] || [ -z "$JOBS" ]; then JOBS="$(nproc)"; fi \
 && make -j"${JOBS}" \
 && make install \
 && make samples \
 && make config \
 && ldconfig \
 && find /usr/sbin /usr/lib/asterisk /usr/lib -type f \( -name 'asterisk' -o -name '*.so' -o -name 'libasterisk*' \) \
      -exec strip --strip-unneeded {} + 2>/dev/null || true \
 && asterisk -V

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
FROM debian:${DEBIAN_VERSION}-slim

ARG ASTERISK_VERSION
ARG BUILD_DATE
ARG VERSION=dev
ARG REVISION=
ARG DEBIAN_VERSION=bookworm

LABEL org.opencontainers.image.title="asterisk" \
      org.opencontainers.image.description="Asterisk LTS built from official sources, with Unraid packaging" \
      org.opencontainers.image.source="https://github.com/pmastalerz/asterisk" \
      org.opencontainers.image.url="https://github.com/pmastalerz/asterisk" \
      org.opencontainers.image.documentation="https://github.com/pmastalerz/asterisk#readme" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.licenses="GPL-2.0-only" \
      org.opencontainers.image.base.name="debian:${DEBIAN_VERSION}-slim" \
      net.unraid.docker.managed="dockerman" \
      net.unraid.docker.icon="https://www.asterisk.org/wp-content/uploads/asterisk-logo.png" \
      net.unraid.docker.shell="bash"

ENV ASTERISK_VERSION=${ASTERISK_VERSION} \
    VERSION=${VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Warsaw \
    PUID=1000 \
    PGID=1000 \
    UMASK=0022

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tzdata \
    gettext-base \
    procps \
    libedit2 \
    libjansson4 \
    libsqlite3-0 \
    libxml2 \
    libxslt1.1 \
    libssl3 \
    libncurses6 \
    libnewt0.52 \
    libspandsp2 \
    libopus0 \
    libopusfile0 \
    libsrtp2-1 \
    libvpx7 \
    libspeex1 \
    libspeexdsp1 \
    libvorbis0a \
    libogg0 \
    libcurl4 \
    libiksemel3 \
    libsnmp40 \
    libcap2 \
    libuuid1 \
    sox \
    && rm -rf /var/lib/apt/lists/*

# Binaries + modules from builder
COPY --from=builder /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=builder /usr/sbin/ast* /usr/sbin/
COPY --from=builder /usr/lib/asterisk /usr/lib/asterisk
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /var/spool/asterisk /var/spool/asterisk
COPY --from=builder /var/log/asterisk /var/log/asterisk
COPY --from=builder /var/run/asterisk /var/run/asterisk
COPY --from=builder /etc/asterisk /etc/asterisk.default

# Keep a pristine copy for bind-mounted /var/lib/asterisk (Unraid appdata).
RUN cp -a /var/lib/asterisk /var/lib/asterisk.default

# Our defaults + entrypoint (Unraid / first-run seed)
COPY root/ /

RUN sed -i 's/\r$//' \
      /entrypoint.sh \
      /app/seed-config.sh \
      /app/seed-varlib.sh \
      /app/render-templates.sh \
      /healthcheck.sh \
 && chmod +x \
      /entrypoint.sh \
      /app/seed-config.sh \
      /app/seed-varlib.sh \
      /app/render-templates.sh \
      /healthcheck.sh \
 && groupadd -r -g 1000 asterisk \
 && useradd -r -u 1000 -g asterisk -d /var/lib/asterisk -s /usr/sbin/nologin asterisk \
 && mkdir -p /etc/asterisk \
 && chown -R asterisk:asterisk \
      /etc/asterisk \
      /etc/asterisk.default \
      /var/lib/asterisk \
      /var/lib/asterisk.default \
      /var/spool/asterisk \
      /var/log/asterisk \
      /var/run/asterisk \
 && ldconfig \
 && asterisk -V

EXPOSE 5060/udp 5060/tcp 8088/tcp 8089/tcp 10000-20000/udp

VOLUME [\
  "/etc/asterisk", \
  "/var/lib/asterisk/db", \
  "/var/lib/asterisk/keys", \
  "/var/lib/asterisk/sounds", \
  "/var/log/asterisk", \
  "/var/spool/asterisk"\
]

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["/healthcheck.sh"]

# -U/-p drop root to the asterisk user after startup (defense-in-depth alongside
# asterisk.conf's runuser= line, so a user-supplied asterisk.conf can't regress it).
# -W is a placeholder the entrypoint swaps for ASTERISK_TERMINAL_OPTS if that env is set.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["asterisk", "-f", "-vvv", "-U", "asterisk", "-p", "-W"]
