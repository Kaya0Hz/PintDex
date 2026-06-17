FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    clang \
    cmake \
    ninja-build \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz \
    | tar xJ -C /opt

ENV PATH=/opt/flutter/bin:$PATH

RUN flutter config --enable-linux-desktop

WORKDIR /app
COPY . .

RUN flutter pub get && flutter build linux --release

FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 \
    libx11-6 \
    libxcb1 \
    libxkbcommon0 \
    libglib2.0-0 \
    libpango-1.0-0 \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    libatk1.0-0 \
    libasound2 \
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
