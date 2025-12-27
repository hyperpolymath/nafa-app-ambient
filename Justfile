# NAFA Ambient Edition Justfile

# Setup
init:
    mix deps.get
    echo "Initialized NAFA Ambient Edition"

config:
    echo "Configure environment variables and API keys"

env:
    echo "GRAPHHOPPER_API_KEY=${GRAPHHOPPER_API_KEY}"

# Routing
route calm from to:
    elixir -e "MoodRouter.score_route(%{from: {$(from)}, to: {$(to)}, profile: \"foot\"})"

route avoid from to avoid:
    elixir -e "RouteFilter.avoid(%{from: {$(from)}, to: {$(to)}, avoid: \"$(avoid)\"})"

route multi points:
    elixir -e "MoodRouter.multi_route($(points))"

# Overlays
overlay scent zone mood:
    elixir -e "AmbientSync.trigger_overlay(%{zone: \"$(zone)\", mood: \"$(mood)\", overlay: :scent})"

overlay haptic zone mood:
    elixir -e "AmbientSync.trigger_overlay(%{zone: \"$(zone)\", mood: \"$(mood)\", overlay: :haptic})"

overlay visual zone mood:
    elixir -e "AmbientSync.trigger_overlay(%{zone: \"$(zone)\", mood: \"$(mood)\", overlay: :visual})"

# Emergency
panic location:
    elixir -e "EmergencyFallback.activate(%{location: \"$(location)\", signal: :panic})"

reroute location:
    elixir -e "EmergencyFallback.activate(%{location: \"$(location)\", signal: :reroute})"

contact person:
    echo "Contacting $(person)..."

# Splash
splash trigger event:
    elixir -e "SplashTrigger.emit(:$(event))"

splash preview:
    cat nickel-rituals/splash.graph

splash graph:
    nickel check nickel-rituals/splash.graph

# Symbolic Rituals
badge tier:
    nickel run nickel-rituals/badge.ncl --tier $(tier)

tier contributor name:
    nickel run nickel-rituals/tier.ncl --contributor $(name)

# MVP Commands
mvp-demo:
    @if command -v deno >/dev/null 2>&1; then \
        cd server && deno task demo; \
    else \
        node server/src/demo-node.js; \
    fi

mvp-server:
    @if command -v deno >/dev/null 2>&1; then \
        cd server && deno task start; \
    else \
        echo "Deno required for server. Install: https://deno.land"; \
    fi

mvp-dev:
    @if command -v deno >/dev/null 2>&1; then \
        cd server && deno task dev; \
    else \
        echo "Deno required for dev server. Install: https://deno.land"; \
    fi

mvp-build:
    @if [ -d shared/node_modules ]; then \
        cd shared && npx rescript build; \
        cd ../client && npx rescript build; \
    else \
        echo "Run 'npm install' in shared/ and client/ first"; \
    fi

mvp-check:
    @if command -v deno >/dev/null 2>&1; then \
        deno check server/src/main.js server/src/demo.js; \
    else \
        node --check server/src/demo-node.js; \
    fi

# Docs & Help
man:
    echo "NAFA Ambient Edition Manual: Routing, Overlays, Emergency, Splash, Rituals"

help:
    echo "Available commands: init, config, env, route calm, route avoid, route multi, overlay scent/haptic/visual, panic, reroute, contact, splash trigger/preview/graph, badge, tier, mvp-demo, mvp-server, mvp-dev, mvp-build, man, help"
