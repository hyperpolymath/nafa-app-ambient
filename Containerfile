#
# === NAFA Containerfile (for Podman) ===
#
# This is a multi-stage build.
# It assumes frontend assets are already compiled and digested
# by 'just build' before this is run.
#

# --- Stage 1: Builder ---
# This stage builds the Elixir release.
FROM docker.io/library/elixir:1.17.0-otp-27-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

WORKDIR /app

# Set production environment
ENV MIX_ENV=prod

# --- Elixir Dependencies ---
# Copy only dependency files first to leverage layer caching
COPY elixir-backend/mix.exs elixir-backend/mix.lock ./elixir-backend/
RUN cd elixir-backend && \
    mix deps.get --only prod && \
    mix deps.compile

# --- Build Release ---
# Copy the rest of the backend app
COPY elixir-backend ./elixir-backend
# Copy the generated production config
COPY config/production.json ./config/production.json

# Copy the pre-built and digested frontend assets
# This is critical: 'just build' must run *before* 'podman build'
COPY elixir-backend/priv/static ./elixir-backend/priv/static

# Compile and build the release
RUN cd elixir-backend && \
    mix compile && \
    mix release nafa

# --- Stage 2: Runtime ---
# This is the final, minimal image.
FROM docker.io/library/alpine:latest AS runtime

# Install runtime dependencies (e.g., OpenSSL)
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

# Set environment variables
ENV PORT=8080
ENV MIX_ENV=prod

# Copy the compiled release from the builder stage
COPY --from=builder /app/elixir-backend/_build/prod/rel/nafa .

# Expose the port defined in the Elixir config (defaults to 8080)
EXPOSE 8080

# Run the application
# We use 'exec' to ensure signals are passed correctly
CMD ["exec", "bin/nafa", "start"]