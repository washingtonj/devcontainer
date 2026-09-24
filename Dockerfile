FROM debian:13-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH
ARG ORCA_VERSION=1.4.205

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl file xz-utils \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/orca /etc/devserver/env.d

COPY --chmod=755 scripts/install-asdf.sh scripts/install-orca.sh /usr/local/lib/devserver/

RUN TARGETARCH="${TARGETARCH:-amd64}" /usr/local/lib/devserver/install-asdf.sh

RUN TARGETARCH="${TARGETARCH:-amd64}" \
    ORCA_VERSION="$ORCA_VERSION" \
    /usr/local/lib/devserver/install-orca.sh

FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    ORCA_PORT=6768

ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git gawk xz-utils unzip bzip2 ripgrep \
    openssh-client openssh-server \
    xvfb zlib1g \
    libgtk-3-0t64 libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 \
    libgbm1 libasound2t64 libxtst6 libcups2t64 libdrm2 libxkbcommon0 \
    libpango-1.0-0 libcairo2 libatspi2.0-0t64 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libxrender1 libx11-xcb1 libxcb-dri3-0 libxss1 \
    libnotify4 xdg-utils libsecret-1-0 \
    python3 python3-gi gir1.2-atspi-2.0 \
    xdotool xclip \
 && apt-mark manual libgbm1 libgl1-mesa-dri libglx-mesa0 \
 && dpkg --purge --force-depends libllvm19 mesa-libgallium libz3-4 2>/dev/null || true \
 && rm -f /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --uid 1000 --create-home --user-group --shell /bin/bash -p '*' agent \
 && mkdir -p /opt/orca /home/agent/workspace /etc/devserver/env.d \
 && ln -s /home/agent/workspace /workspace

COPY --from=builder --chmod=755 /opt/orca/opt/Orca /opt/Orca
COPY --from=builder /usr/local/bin/asdf /usr/local/bin/asdf
COPY --from=builder /etc/devserver/env.d/asdf.env /etc/devserver/env.d/asdf.env
COPY --from=builder /etc/profile.d/asdf.sh /etc/profile.d/asdf.sh

COPY --chmod=755 \
    scripts/install-ssh.sh \
    scripts/configure-runtime.sh \
    scripts/configure-ssh.sh \
    scripts/start-orca.sh \
    scripts/entrypoint.sh \
    /usr/local/lib/devserver/

RUN /usr/local/lib/devserver/install-ssh.sh

WORKDIR /home/agent

EXPOSE 22 6768

ENTRYPOINT ["/usr/local/lib/devserver/entrypoint.sh"]
