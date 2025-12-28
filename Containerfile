# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 hyperpolymath
#
# === NAFA Containerfile (Deno Runtime) ===
#
# Multi-stage build for the NAFA server.
# Uses Deno for the runtime - no node_modules needed.
#

# --- Stage 1: Builder ---
FROM docker.io/denoland/deno:alpine AS builder

WORKDIR /app

# Copy server source
COPY server/ ./server/
COPY shared/ ./shared/

# Cache dependencies (Deno caches on first run)
RUN cd server && deno cache src/main.js

# --- Stage 2: Runtime ---
FROM docker.io/denoland/deno:alpine AS runtime

WORKDIR /app

# Copy from builder
COPY --from=builder /app/server ./server
COPY --from=builder /app/shared ./shared
COPY --from=builder /root/.cache/deno /root/.cache/deno

# Set environment
ENV PORT=8080

# Expose the port
EXPOSE 8080

# Run with minimal permissions
CMD ["deno", "run", "--allow-net", "--allow-read", "--allow-env", "server/src/main.js"]
