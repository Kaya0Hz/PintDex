# syntax = docker/dockerfile:1.7
FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    clang \
    cmake \
    ninja-build \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/opt/flutter \
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz \
    | tar xJ -C /opt

ENV PATH=/opt/flutter/bin:$PATH

RUN git config --global --add safe.directory /opt/flutter \
  && flutter config --enable-linux-desktop --no-analytics

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get

COPY . .

RUN --mount=type=cache,target=/root/.pub-cache \
    flutter build linux --release

FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS runtime

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 \
    libx11-6 \
    libxcb1 \
    libxkbcommon0 \
    libglib2.0-0 \
    libpango-1.0-0 \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    libatk1.0-0 \
    libasound2t64 \
    liblzma5 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r pintdex && useradd -r -g pintdex -d /data -s /sbin/nologin pintdex

COPY --from=build --chown=pintdex:pintdex /app/build/linux/x64/release/bundle /app

ENV HOME=/data

VOLUME /data

USER pintdex

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["test", "-f", "/app/pintdex"]

ENTRYPOINT ["/app/pintdex"]
