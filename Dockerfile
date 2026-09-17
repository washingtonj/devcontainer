FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    ORCA_PORT=6768

ARG TARGETARCH
ARG ORCA_APPIMAGE_URL=""

RUN userdel --remove ubuntu || true \
    && groupdel ubuntu || true \
    && useradd --uid 1000 --create-home --user-group --shell /bin/bash agent \
    && mkdir -p /opt/orca /home/agent/workspace \
    && ln -s /home/agent/workspace /workspace \
    && chown -R agent:agent /home/agent/workspace

COPY --chmod=755 scripts/install-ssh.sh \
     scripts/install-asdf-node.sh \
     scripts/install-orca.sh \
     /usr/local/lib/devserver/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    chmod +x /usr/local/lib/devserver/*.sh \
    && /usr/local/lib/devserver/install-ssh.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    ASDF_DATA_DIR=/opt/devserver/agent-home/.asdf \
    /usr/local/lib/devserver/install-asdf-node.sh \
    && if [ -f /home/agent/.tool-versions ]; then \
         cp -a /home/agent/.tool-versions /opt/devserver/agent-home/.tool-versions; \
       fi

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    TARGETARCH="${TARGETARCH:-amd64}" \
    ORCA_APPIMAGE_URL="$ORCA_APPIMAGE_URL" \
    /usr/local/lib/devserver/install-orca.sh

COPY --chmod=755 scripts/configure-ssh.sh \
     scripts/entrypoint.sh \
     scripts/prepare-agent-runtime.sh \
     scripts/start-orca.sh \
     /usr/local/lib/devserver/

RUN chmod +x /usr/local/lib/devserver/*.sh \
    && chmod 755 /usr/local/lib/devserver/entrypoint.sh \
    && chown -R agent:agent /opt/devserver/agent-home

WORKDIR /home/agent

EXPOSE 22 6768

ENTRYPOINT ["/usr/local/lib/devserver/entrypoint.sh"]
