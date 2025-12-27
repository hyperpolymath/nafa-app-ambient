# Migration Plan: Elm → rescript-tea + cadre-router

## Overview

Migrate nafa-app-ambient from Elm to a ReScript-first architecture using:
- **rescript-tea** for client-side TEA architecture
- **cadre-router** for typed client-side URL parsing (Parser, Navigation, Link)
- **cadre-tea-router** for TEA integration (TeaRouter.Make functor)
- **Shared types** for compile-time guarantees across the stack

## Dependency Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                        nafa-app-ambient                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌──────────────────┐    ┌────────────────┐ │
│  │ rescript-tea│◄───│ cadre-tea-router │◄───│  cadre-router  │ │
│  │             │    │                  │    │                │ │
│  │ TEA loop    │    │ TeaRouter.Make   │    │ Parser (s,str) │ │
│  │ Cmd/Sub     │    │ Tea.Cmd.t        │    │ Navigation     │ │
│  │ Html/View   │    │ Tea.Sub.t        │    │ Link.Make      │ │
│  └─────────────┘    └──────────────────┘    └────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Locations

| Package | Location | Status |
|---------|----------|--------|
| cadre-router | `hyperpolymath/cadre-router` (branch `claude/type-safe-routing-SPtP7`) | Client-side routing |
| cadre-tea-router | Needs GitHub repo | TEA integration layer |
| Server-side routing | Future work (Stage 3 in roadmap) | Not implemented |

## Phase 1: Monorepo Structure

### Target Layout

```
nafa-app-ambient/
├── client/                         # Browser SPA
│   ├── src/
│   │   ├── Main.res               # App entry, navigationProgram
│   │   ├── Routing.res            # Location.t → Route.t parser
│   │   ├── Ports.res              # JS interop bindings
│   │   ├── Page/
│   │   │   ├── MoodInput.res
│   │   │   ├── RoutePlanner.res
│   │   │   ├── Journey.res
│   │   │   ├── Profile.res
│   │   │   └── NotFound.res
│   │   └── Component/             # Reusable UI components
│   ├── index.html
│   ├── rescript.json
│   └── package.json               # rescript-tea, react deps
│
├── server/                         # Deno API server
│   ├── src/
│   │   ├── Main.res               # Server entry
│   │   ├── Routes/
│   │   │   ├── Mood.res           # POST /api/mood
│   │   │   ├── Journey.res        # GET/POST /api/journey/:id
│   │   │   └── Profile.res        # GET/PUT /api/profile
│   │   ├── Middleware/
│   │   │   ├── Auth.res
│   │   │   └── Session.res
│   │   └── State/                 # Optional CRDT state
│   ├── rescript.json
│   └── deno.json
│
├── shared/                         # Shared types (both client & server)
│   ├── src/
│   │   ├── Route.res              # Route variant type
│   │   ├── Api.res                # Request/response types
│   │   ├── Domain.res             # Badge, Tier, Journey, User types
│   │   └── Codec.res              # JSON encode/decode
│   └── rescript.json
│
├── src/                            # Legacy Elm (to be removed)
│   ├── Main.elm
│   ├── Routing.elm
│   └── ...
│
├── nickel-rituals/                 # Existing config (unchanged)
├── scripts/                        # Build/dev scripts
├── elm.json                        # Legacy (to be removed)
└── PLAN.md                         # This file
```

---

## Step-by-Step Implementation

### Step 1: Initialize Monorepo Structure

```bash
mkdir -p client/src/Page client/src/Component
mkdir -p server/src/Routes server/src/Middleware server/src/State
mkdir -p shared/src
```

Create workspace rescript.json files for each package.

### Step 2: Shared Types (shared/)

Port Elm types to ReScript:

**shared/src/Domain.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

type badge =
  | Initiate
  | Pathfinder
  | Wayfarer
  | Trailblazer
  | Luminary

type user = {
  id: string,
  name: string,
  badge: badge,
}

type session = {
  user: user,
  token: string,
}

type moodEntry = {
  timestamp: float,
  level: int,        // 1-5
  notes: option<string>,
}

type journey = {
  id: string,
  title: string,
  waypoints: array<waypoint>,
  status: journeyStatus,
}

and waypoint = {
  id: string,
  name: string,
  completed: bool,
}

and journeyStatus =
  | Planning
  | Active
  | Completed
  | Paused
```

**shared/src/Route.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// Route type and cadre-router parser integration

type t =
  | Home
  | MoodInput
  | RoutePlanner
  | Journey(string)  // journey ID
  | Profile
  | NotFound

// Elm-style parser using cadre-router combinators
let parser = {
  open CadreRouter.Parser
  oneOf([
    map(Home, top),
    map(MoodInput, s("mood")),
    map(RoutePlanner, s("plan")),
    map(id => Journey(id), s("journey") </> str),
    map(Profile, s("profile")),
  ])
}

let toString = (route: t): string => {
  switch route {
  | Home => "/"
  | MoodInput => "/mood"
  | RoutePlanner => "/plan"
  | Journey(id) => "/journey/" ++ id
  | Profile => "/profile"
  | NotFound => "/404"
  }
}

// Type-safe Link component for this route type
module Link = CadreRouter.Link.Make({
  type t = t
  let toString = toString
})
```

**shared/src/Api.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// API request/response types shared between client and server

module Mood = {
  type logRequest = {
    level: int,
    notes: option<string>,
  }

  type logResponse = {
    success: bool,
    entry: Domain.moodEntry,
  }
}

module Journey = {
  type getResponse = {
    journey: Domain.journey,
  }

  type createRequest = {
    title: string,
  }
}

module Profile = {
  type getResponse = {
    user: Domain.user,
    stats: userStats,
  }

  and userStats = {
    journeysCompleted: int,
    currentStreak: int,
    totalMoodLogs: int,
  }
}
```

### Step 3: Client Setup (client/)

**client/rescript.json**
```json
{
  "name": "nafa-client",
  "sources": [
    {"dir": "src", "subdirs": true},
    {"dir": "../shared/src", "subdirs": true}
  ],
  "package-specs": [{
    "module": "es6",
    "in-source": true
  }],
  "suffix": ".res.js",
  "bs-dependencies": [
    "rescript-tea",
    "cadre-router",
    "cadre-tea-router",
    "@rescript/react"
  ],
  "jsx": {"version": 4, "mode": "automatic"},
  "warnings": {"number": "-44"}
}
```

**client/src/Router.res** (replaces hand-rolled Routing.res)
```rescript
// SPDX-License-Identifier: Apache-2.0

// TeaRouter integration using cadre-tea-router functor

module Router = TeaRouter.Make({
  type route = Route.t
  type msg = Msg.t

  let parser = Route.parser        // cadre-router Parser
  let toString = Route.toString

  let onRouteChange = route => Msg.RouteChanged(route)
  let onNotFound = url => Msg.UrlNotFound(url)
})

// Re-export for convenience
let init = Router.init
let update = Router.update
let subscriptions = Router.subscriptions
let navigate = Router.navigate
let link = Router.link
```

**client/src/Msg.res** (message types)
```rescript
// SPDX-License-Identifier: Apache-2.0

type t =
  | RouteChanged(Route.t)
  | UrlNotFound(CadreRouter.Url.t)
  | MoodInputMsg(PageMoodInput.msg)
  | RoutePlannerMsg(PageRoutePlanner.msg)
  | JourneyMsg(PageJourney.msg)
  | ProfileMsg(PageProfile.msg)
  | SessionLoaded(Domain.session)
  | ApiError(string)
```

**client/src/Main.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// Main application using rescript-tea + cadre-tea-router

type page =
  | NotFoundPage(PageNotFound.model)
  | MoodInputPage(PageMoodInput.model)
  | RoutePlannerPage(PageRoutePlanner.model)
  | JourneyPage(PageJourney.model)
  | ProfilePage(PageProfile.model)

type model = {
  route: Route.t,
  page: page,
  session: option<Domain.session>,
}

let initPage = (route: Route.t, session: option<Domain.session>): (page, Tea.Cmd.t<Msg.t>) => {
  switch route {
  | Route.Home | Route.MoodInput =>
    let (model, cmd) = PageMoodInput.init()
    (MoodInputPage(model), Tea.Cmd.map(msg => Msg.MoodInputMsg(msg), cmd))

  | Route.RoutePlanner =>
    let (model, cmd) = PageRoutePlanner.init()
    (RoutePlannerPage(model), Tea.Cmd.map(msg => Msg.RoutePlannerMsg(msg), cmd))

  | Route.Journey(id) =>
    let (model, cmd) = PageJourney.init(id, session)
    (JourneyPage(model), Tea.Cmd.map(msg => Msg.JourneyMsg(msg), cmd))

  | Route.Profile =>
    let (model, cmd) = PageProfile.init(session)
    (ProfilePage(model), Tea.Cmd.map(msg => Msg.ProfileMsg(msg), cmd))

  | Route.NotFound =>
    (NotFoundPage(PageNotFound.init()), Tea.Cmd.none)
  }
}

let init = (): (model, Tea.Cmd.t<Msg.t>) => {
  // Router handles initial URL parsing via subscriptions
  let mockSession = Some({
    Domain.user: {
      id: "user-123",
      name: "Adventurer",
      badge: Domain.Initiate,
    },
    token: "mock-token",
  })

  let (page, pageCmd) = initPage(Route.Home, mockSession)
  ({route: Route.Home, page, session: mockSession}, pageCmd)
}

let update = (msg: Msg.t, model: model): (model, Tea.Cmd.t<Msg.t>) => {
  switch msg {
  | Msg.RouteChanged(route) =>
    let (page, cmd) = initPage(route, model.session)
    ({...model, route, page}, cmd)

  | Msg.UrlNotFound(_url) =>
    let (page, cmd) = initPage(Route.NotFound, model.session)
    ({...model, route: Route.NotFound, page}, cmd)

  | Msg.MoodInputMsg(pageMsg) =>
    switch model.page {
    | MoodInputPage(pageModel) =>
      let (newModel, cmd) = PageMoodInput.update(pageMsg, pageModel)
      ({...model, page: MoodInputPage(newModel)}, Tea.Cmd.map(m => Msg.MoodInputMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | Msg.RoutePlannerMsg(pageMsg) =>
    switch model.page {
    | RoutePlannerPage(pageModel) =>
      let (newModel, cmd) = PageRoutePlanner.update(pageMsg, pageModel)
      ({...model, page: RoutePlannerPage(newModel)}, Tea.Cmd.map(m => Msg.RoutePlannerMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | Msg.JourneyMsg(pageMsg) =>
    switch model.page {
    | JourneyPage(pageModel) =>
      let (newModel, cmd) = PageJourney.update(pageMsg, pageModel)
      ({...model, page: JourneyPage(newModel)}, Tea.Cmd.map(m => Msg.JourneyMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | Msg.ProfileMsg(pageMsg) =>
    switch model.page {
    | ProfilePage(pageModel) =>
      let (newModel, cmd) = PageProfile.update(pageMsg, pageModel)
      ({...model, page: ProfilePage(newModel)}, Tea.Cmd.map(m => Msg.ProfileMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | Msg.SessionLoaded(session) =>
    ({...model, session: Some(session)}, Tea.Cmd.none)

  | Msg.ApiError(_) =>
    (model, Tea.Cmd.none)
  }
}

let view = (model: model): Tea.Html.t<Msg.t> => {
  open Tea.Html

  let pageView = switch model.page {
  | NotFoundPage(m) => PageNotFound.view(m)
  | MoodInputPage(m) => Tea.Html.map(msg => Msg.MoodInputMsg(msg), PageMoodInput.view(m))
  | RoutePlannerPage(m) => Tea.Html.map(msg => Msg.RoutePlannerMsg(msg), PageRoutePlanner.view(m))
  | JourneyPage(m) => Tea.Html.map(msg => Msg.JourneyMsg(msg), PageJourney.view(m))
  | ProfilePage(m) => Tea.Html.map(msg => Msg.ProfileMsg(msg), PageProfile.view(m))
  }

  div([class'("app")], [
    // Navigation using type-safe links
    nav([class'("nav")], [
      Route.Link.make(~route=Route.MoodInput, ~children=[text("Mood")], ()),
      Route.Link.make(~route=Route.RoutePlanner, ~children=[text("Plan")], ()),
      Route.Link.make(~route=Route.Profile, ~children=[text("Profile")], ()),
    ]),
    main([], [pageView]),
  ])
}

let subscriptions = (model: model): Tea.Sub.t<Msg.t> => {
  Tea.Sub.batch([
    // Router subscription for URL changes
    Router.subscriptions,

    // Page-specific subscriptions
    switch model.page {
    | JourneyPage(m) => Tea.Sub.map(msg => Msg.JourneyMsg(msg), PageJourney.subscriptions(m))
    | _ => Tea.Sub.none
    },
  ])
}

// Application entry point
let main = Tea.App.program({
  init: init,
  update: update,
  view: view,
  subscriptions: subscriptions,
})
```

### Step 4: Server Setup (server/) — FUTURE WORK

> **Note**: Server-side cadre-router is Stage 3 in the roadmap. For Phase 1, use a
> simple Deno HTTP server or Gleam backend. The typed server-side routing with
> middleware and CRDT state will come later.

**server/deno.json** (minimal for now)
```json
{
  "name": "nafa-server",
  "version": "0.1.0",
  "tasks": {
    "dev": "deno run --watch --allow-net --allow-read src/main.ts",
    "start": "deno run --allow-net --allow-read src/main.ts"
  }
}
```

**server/src/main.ts** (placeholder until server-side cadre-router exists)
```typescript
// SPDX-License-Identifier: Apache-2.0
// Temporary: Simple Deno server until cadre-router server-side is ready

const handler = (request: Request): Response => {
  const url = new URL(request.url);

  // Basic API routing
  if (url.pathname.startsWith("/api/")) {
    return Response.json({ status: "ok" });
  }

  return new Response("NAFA API", { status: 200 });
};

Deno.serve({ port: 8000 }, handler);
```

### Step 5: Page Module Template

**client/src/Page/MoodInput.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

type model = {
  currentLevel: option<int>,
  notes: string,
  submitting: bool,
}

type msg =
  | SetLevel(int)
  | SetNotes(string)
  | Submit
  | SubmitResult(result<Api.Mood.logResponse, string>)
  | NoOp

let init = (): (model, Tea.Cmd.t<msg>) => {
  ({currentLevel: None, notes: "", submitting: false}, Tea.Cmd.none)
}

let update = (msg: msg, model: model): (model, Tea.Cmd.t<msg>) => {
  switch msg {
  | SetLevel(level) => ({...model, currentLevel: Some(level)}, Tea.Cmd.none)
  | SetNotes(notes) => ({...model, notes: notes}, Tea.Cmd.none)
  | Submit =>
    switch model.currentLevel {
    | Some(level) =>
      let cmd = Tea.Cmd.none // TODO: API call
      ({...model, submitting: true}, cmd)
    | None => (model, Tea.Cmd.none)
    }
  | SubmitResult(Ok(_)) =>
    ({currentLevel: None, notes: "", submitting: false}, Routing.navigate(Route.RoutePlanner))
  | SubmitResult(Error(_)) =>
    ({...model, submitting: false}, Tea.Cmd.none)
  | NoOp => (model, Tea.Cmd.none)
  }
}

let view = (model: model): Tea.Html.t<msg> => {
  open Tea.Html

  div([class'("mood-input-page")], [
    h1([], [text("How are you feeling?")]),
    div([class'("mood-selector")],
      Belt.Array.map([1, 2, 3, 4, 5], level =>
        button([
          class'(model.currentLevel == Some(level) ? "selected" : ""),
          onClick(SetLevel(level)),
        ], [text(Belt.Int.toString(level))])
      )->Belt.List.fromArray
    ),
    textarea([
      placeholder("Optional notes..."),
      value(model.notes),
      onInput(s => SetNotes(s)),
    ], []),
    button([
      onClick(Submit),
      disabled(model.submitting || model.currentLevel == None),
    ], [text(model.submitting ? "Saving..." : "Continue")]),
  ])
}
```

---

## Step 6: Build & Dev Scripts

**scripts/dev.sh**
```bash
#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Run client and server in parallel

# Build shared types first
(cd shared && npx rescript build)

# Start client dev server and server
(cd client && npx rescript build -w) &
(cd server && deno task dev) &

wait
```

**Justfile additions**
```just
# ReScript development
rs-build:
    cd shared && npx rescript build
    cd client && npx rescript build
    cd server && npx rescript build

rs-dev:
    ./scripts/dev.sh

rs-clean:
    cd shared && npx rescript clean
    cd client && npx rescript clean
    cd server && npx rescript clean
```

---

## Migration Checklist

### Immediate (Structure)
- [ ] Create directory structure (client/, server/, shared/)
- [ ] Initialize rescript.json for each package
- [ ] Set up shared type definitions
- [ ] Configure deno.json for server

### Client Migration
- [ ] Port Domain types from Types.elm → shared/src/Domain.res
- [ ] Port Route type from Routing.elm → shared/src/Route.res
  - [ ] Add `parser` using cadre-router combinators (`s`, `str`, `</>`, `oneOf`)
  - [ ] Add `toString` for serialization
  - [ ] Add `module Link = CadreRouter.Link.Make(...)` for type-safe links
- [ ] Create client/src/Msg.res with message type
- [ ] Create client/src/Router.res using `TeaRouter.Make` functor
- [ ] Implement Main.res with:
  - [ ] `Router.urlChanges` in subscriptions
  - [ ] `Router.push` for navigation commands
  - [ ] `Router.link` or `Route.Link.make` for links in view
- [ ] Port each Page module:
  - [ ] Page/MoodInput.res
  - [ ] Page/RoutePlanner.res
  - [ ] Page/Journey.res
  - [ ] Page/Profile.res
  - [ ] Page/NotFound.res
- [ ] Port Ports.elm → client/src/Ports.res

### Server Setup (Phase 1 — Minimal)
- [ ] Create basic Deno HTTP server (placeholder)
- [ ] Implement minimal API endpoints
- [ ] Configure CORS for local development
- [ ] (Future) Server-side cadre-router when Stage 3 is ready

### Integration
- [ ] Client fetches from server API
- [ ] Shared types ensure contract consistency
- [ ] Test full round-trip (UI → API → Response → UI)

### Cleanup
- [ ] Remove src/*.elm files
- [ ] Remove elm.json
- [ ] Update .gitignore for ReScript artifacts
- [ ] Update CI/build scripts

---

## Dependencies to Install

### Client
```bash
cd client
npm init -y
npm install rescript rescript-tea @rescript/react react react-dom
```

### Server
```bash
cd server
# Deno manages deps via deno.json imports
```

---

## Resolved Questions

1. **Routing Architecture**: Using `cadre-tea-router` functor pattern
   - Define `parser` and `toString` once
   - Get `Router.push`, `Router.urlChanges`, `Router.link` — all type-safe

2. **cadre-router Location**: `hyperpolymath/cadre-router` branch `claude/type-safe-routing-SPtP7`
   - Client-side only (Parser, Navigation, Link)
   - Server-side is Stage 3 future work

3. **cadre-tea-router**: Needs GitHub repo (currently local only)
   - Provides `TeaRouter.Make` functor
   - Bridges cadre-router ↔ rescript-tea

## Open Questions

1. **UI Library**: rescript-tea uses virtual DOM. Options:
   - Pure `Tea.Html` (like elm-html) — simpler, lighter
   - React via `@rescript/react` — richer ecosystem
   - Hybrid: Tea.Html for pages, React for complex components

2. **cadre-tea-router publishing**: Create GitHub repo and publish to npm?

---

## Timeline-Free Milestones

1. **Scaffold**: Directory structure + configs
2. **Types**: Shared domain types compiling
3. **Routing**: Client routing working with mock pages
4. **Pages**: All pages ported with static content
5. **API**: Server routes returning mock data
6. **Integration**: Client calling server, full flow
7. **Cleanup**: Elm removed, production-ready
