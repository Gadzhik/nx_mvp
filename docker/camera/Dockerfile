FROM ubuntu:22.04

LABEL maintainer="NX Witness QA Lab"
LABEL description="Virtual RTSP camera for NX Witness testing"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install FFmpeg and RTSP server
RUN apt-get update && apt-get install -y \
    ffmpeg \
    mediainfo \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install MediaMTX (RTSP server)
RUN wget -qO /tmp/mediamtx.tar.gz https://github.com/bluenviron/mediamtx/releases/download/v1.9.3/mediamtx_v1.9.3_linux_amd64.tar.gz && \
    tar -xzf /tmp/mediamtx.tar.gz -C /tmp && \
    mv /tmp/mediamtx /usr/local/bin/ && \
    rm -f /tmp/mediamtx.tar.gz

# Create MediaMTX config directory
RUN mkdir -p /etc/mediamtx

# Copy MediaMTX configuration file
COPY mediamtx.yml /etc/mediamtx/mediamtx.yml

# Create directory for video sources
RUN mkdir -p /video-sources

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
RTSP_PORT=${RTSP_PORT:-8554}\n\
CAMERA_NAME=${CAMERA_NAME:-camera}\n\
VIDEO_FILE=/video-sources/test.mp4\n\
MEDIAMTX_CONFIG=/etc/mediamtx/mediamtx.yml\n\
\n\
echo "Starting RTSP Camera..."\n\
echo "RTSP Port: $RTSP_PORT"\n\
echo "Camera Name: $CAMERA_NAME"\n\
echo "MediaMTX Config: $MEDIAMTX_CONFIG"\n\
\n\
# Check if video file exists\n\
if [ -f "$VIDEO_FILE" ]; then\n\
    echo "Using video source: $VIDEO_FILE"\n\
    # Start MediaMTX RTSP server in background with config file\n\
    mediamtx "$MEDIAMTX_CONFIG" &\n\
    MEDIAMTX_PID=$!\n\
    \n\
    # Wait for RTSP server to start\n\
    sleep 2\n\
    \n\
    # Stream MP4 file to RTSP\n\
    ffmpeg -re -i "$VIDEO_FILE" \\\n\
        -c:v libx264 -preset ultrafast -tune zerolatency \\\n\
        -an \\\n\
        -f rtsp "rtsp://localhost:$RTSP_PORT/$CAMERA_NAME" \\\n\
        -loglevel warning\n\
else\n\
    echo "No video file found, using synthetic video source"\n\
    # Start MediaMTX RTSP server in background with config file\n\
    mediamtx "$MEDIAMTX_CONFIG" &\n\
    MEDIAMTX_PID=$!\n\
    \n\
    # Wait for RTSP server to start\n\
    sleep 2\n\
    \n\
    # Generate synthetic video and stream to RTSP\n\
    ffmpeg -re -f lavfi -i testsrc=size=640x480:rate=30 \\\n\
        -c:v libx264 -preset ultrafast -tune zerolatency \\\n\
        -f rtsp "rtsp://localhost:$RTSP_PORT/$CAMERA_NAME" \\\n\
        -loglevel warning\n\
fi\n\
' > /start-camera.sh && chmod +x /start-camera.sh

# Expose RTSP port
EXPOSE 8554

# Set working directory
WORKDIR /video-sources

# Start RTSP camera
CMD ["/start-camera.sh"]
