FROM ubuntu:24.04

LABEL maintainer="NX Witness QA Lab"
LABEL description="NX Witness Server container for QA testing"

# Build argument for NX Witness binary filename
ARG NX_BINARY_FILE=nxwitness-server-*.deb

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfontconfig1 \
    libgl1-mesa-dri \
    libglib2.0-0 \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2t64 \
    libatspi2.0-0 \
    libdrm2 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    libxkbcommon0 \
    cifs-utils \
    file \
    libcap2-bin \
    net-tools \
    libstdc++-13-dev \
    && rm -rf /var/lib/apt/lists/*

# Create directory for NX Witness
RUN mkdir -p /opt/networkoptix/mediaserver/data

# Copy NX Witness binary from build context (root directory)
COPY nx-binary/${NX_BINARY_FILE} /tmp/mediaserver.deb

# Install NX Witness Server
RUN dpkg -i /tmp/mediaserver.deb || apt-get install -f -y

# Create symbolic link for backward compatibility
RUN ln -sf /opt/networkoptix/mediaserver /opt/networkoptix/nxwitness-server && \
    ln -sf /opt/networkoptix/mediaserver/bin/mediaserver /opt/networkoptix/mediaserver/bin/nxwitness-server

# Clean up
RUN rm -f /tmp/mediaserver.deb

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting NX Witness Server..."\n\
\n\
# Ensure data directory exists\n\
mkdir -p /opt/networkoptix/mediaserver/data\n\
\n\
# Start NX Witness Server in background\n\
/opt/networkoptix/mediaserver/bin/mediaserver \\\n\
    --data-dir=/opt/networkoptix/mediaserver/data \\\n\
    --no-sandbox \\\n\
    --disable-gpu \\\n\
    --headless \\\n\
    &\n\
\n\
SERVER_PID=$!\n\
\n\
echo "NX Witness Server started with PID: $SERVER_PID"\n\
\n\
# Wait for server process\n\
wait $SERVER_PID\n\
' > /start-nxwitness.sh && chmod +x /start-nxwitness.sh

# Expose NX Witness Server ports
# 7001: HTTP API
# 7002: HTTPS API
# 7003: Media port
EXPOSE 7001 7002 7003

# Set working directory
WORKDIR /opt/networkoptix/mediaserver

# Start NX Witness Server
CMD ["/start-nxwitness.sh"]
