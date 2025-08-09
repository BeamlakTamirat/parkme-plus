# =============================================================================
# ParkMe Plus 
# =============================================================================
# Base: Ubuntu 24.04 (pinned)
# SDK:  Flutter 3.38.9 / Dart 3.10.8 (pinned via versioned archive URL)
# =============================================================================

FROM ubuntu:24.04

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_VERSION=3.38.9 \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/opt/pub-cache

ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PUB_CACHE}/bin:${PATH}"

# ---------------------------------------------------------------------------
# System dependencies (minimal set for headless Flutter/Dart testing)
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Flutter SDK — downloaded from official versioned archive
# ---------------------------------------------------------------------------
RUN curl -fsSL \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz && \
    tar xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz && \
    git config --global --add safe.directory "${FLUTTER_HOME}" && \
    flutter config --no-analytics && \
    dart --disable-analytics && \
    flutter precache --universal

# ---------------------------------------------------------------------------
# Project source
# ---------------------------------------------------------------------------
WORKDIR /app
COPY . .

# ---------------------------------------------------------------------------
# Resolve dependencies for every package in the monorepo
# Order: shared first (no local deps), then each app (depends on shared)
# ---------------------------------------------------------------------------
RUN git config --global --add safe.directory /app && \
    cd /app/packages/shared && flutter pub get && \
    cd /app/packages/apps/user_app && flutter pub get && \
    cd /app/packages/apps/admin_app && flutter pub get && \
    cd /app/packages/apps/attendant_app && flutter pub get

# Default shell for task harness
CMD ["bash"]
