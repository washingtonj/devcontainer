FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    ORCA_PORT=6768

ARG TARGETARCH
ARG ORCA_APPIMAGE_URL=""

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl file jq git gawk xz-utils \
    openssh-client openssh-server \
    xvfb zlib1g-dev \
    libgtk-3-0t64 libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 \
    libgbm1 libasound2t64 libxtst6 libcups2t64 libdrm2 libxkbcommon0 \
    libpango-1.0-0 libcairo2 libatspi2.0-0t64 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libxrender1 libx11-xcb1 libxcb-dri3-0 libxss1 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --uid 1000 --create-home --user-group --shell /bin/bash agent \
 && sed -i 's|^agent:!:|agent::|' /etc/shadow \
 && mkdir -p /opt/orca /home/agent/workspace /etc/devserver/env.d \
 && ln -s /home/agent/workspace /workspace

COPY --chmod=755 \
    scripts/install-asdf.sh \
    scripts/install-orca.sh \
    /usr/local/lib/devserver/

RUN TARGETARCH="${TARGETARCH:-amd64}" /usr/local/lib/devserver/install-asdf.sh

RUN TARGETARCH="${TARGETARCH:-amd64}" \
    ORCA_APPIMAGE_URL="$ORCA_APPIMAGE_URL" \
    /usr/local/lib/devserver/install-orca.sh

COPY --chmod=755 \
    scripts/configure-runtime.sh \
    scripts/configure-ssh.sh \
    scripts/start-orca.sh \
    scripts/entrypoint.sh \
    /usr/local/lib/devserver/

WORKDIR /home/agent

EXPOSE 22 6768

ENTRYPOINT ["/usr/local/lib/devserver/entrypoint.sh"]
