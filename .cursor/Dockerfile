# Cloud Agent base image: CLI-only Aseprite (source build) + aseprite-mcp.
# Do not COPY the Unity project — Cursor checks out the workspace separately.
# Aseprite EULA: compile for personal/private use only; do not publish this binary.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    ASEPRITE_PATH=/usr/local/bin/aseprite \
    PATH="/root/.local/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}"

ARG ASEPRITE_GIT_REF=v1.3.18.6

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    cmake \
    curl \
    g++ \
    git \
    libc++-dev \
    libc++abi-dev \
    libfontconfig1 \
    libfontconfig1-dev \
    libgl1-mesa-dev \
    libx11-6 \
    libx11-dev \
    libxcursor-dev \
    libxcursor1 \
    libxext6 \
    libxi-dev \
    libxrandr-dev \
    libxrandr2 \
    ninja-build \
    python-is-python3 \
    python3 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# --- Build headless Aseprite (no UI / no Skia; scripting ON for MCP Lua) ---
WORKDIR /tmp/aseprite-src
RUN git clone --depth 1 --recursive --branch "${ASEPRITE_GIT_REF}" \
      https://github.com/aseprite/aseprite.git . \
 && mkdir build && cd build \
 && export CC=clang CXX=clang++ \
 && cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS:STRING=-stdlib=libc++ \
      -DCMAKE_EXE_LINKER_FLAGS:STRING=-stdlib=libc++ \
      -DLAF_BACKEND=none \
      -DENABLE_UI=OFF \
      -DENABLE_SCRIPTING=ON \
      -DENABLE_CCACHE=OFF \
      -G Ninja \
      .. \
 && ninja -j2 aseprite \
 && install -d /opt/aseprite/bin \
 && cp -a bin/. /opt/aseprite/bin/ \
 && ln -sf /opt/aseprite/bin/aseprite /usr/local/bin/aseprite \
 && ln -sf /opt/aseprite/bin/aseprite /usr/local/bin/ase \
 && /usr/local/bin/aseprite --version \
 && cd / && rm -rf /tmp/aseprite-src

# --- uv + aseprite-mcp (stdio MCP server) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
 && ln -sf /root/.local/bin/uv /usr/local/bin/uv \
 && git clone --depth 1 https://github.com/diivi/aseprite-mcp.git /opt/aseprite-mcp \
 && cd /opt/aseprite-mcp \
 && uv sync \
 && printf 'ASEPRITE_PATH=/usr/local/bin/aseprite\n' > /opt/aseprite-mcp/.env \
 && chmod -R a+rwX /opt/aseprite-mcp

WORKDIR /workspace

# Smoke-check Aseprite is on PATH for Cloud Agent stdio MCP
RUN aseprite --version && uv --version
