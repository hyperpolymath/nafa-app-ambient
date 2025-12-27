# Migration Plan: Elm → rescript-tea + cadre-router

## Overview

Migrate nafa-app-ambient from Elm to a ReScript-first architecture using:
- **rescript-tea** for client-side TEA architecture
- **cadre-router** for server-side API routing
- **Shared types** for compile-time guarantees across the stack

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

type t =
  | Home
  | MoodInput
  | RoutePlanner
  | Journey(string)  // journey ID
  | Profile
  | NotFound

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
  "bs-dependencies": ["rescript-tea", "@rescript/react"],
  "jsx": {"version": 4, "mode": "automatic"},
  "warnings": {"number": "-44"}
}
```

**client/src/Routing.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// Client-side route parsing from tea_navigation Location

let fromLocation = (loc: Tea_navigation.Location.t): Route.t => {
  let path = loc.pathname

  // Handle trailing slashes
  let normalized = switch Js.String2.endsWith(path, "/") && path !== "/" {
  | true => Js.String2.slice(path, ~from=0, ~to_=Js.String2.length(path) - 1)
  | false => path
  }

  switch normalized {
  | "/" | "" => Route.Home
  | "/mood" => Route.MoodInput
  | "/plan" => Route.RoutePlanner
  | "/profile" => Route.Profile
  | _ =>
    // Check for /journey/:id pattern
    let segments = Js.String2.split(normalized, "/")
    switch segments {
    | ["", "journey", id] if id !== "" => Route.Journey(id)
    | _ => Route.NotFound
    }
  }
}

// Generate navigation command
let navigate = (route: Route.t): Tea.Cmd.t<'msg> => {
  Tea_navigation.newUrl(Route.toString(route))
}
```

**client/src/Main.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// Main application entry point using rescript-tea

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

type msg =
  | UrlChanged(Tea_navigation.Location.t)
  | MoodInputMsg(PageMoodInput.msg)
  | RoutePlannerMsg(PageRoutePlanner.msg)
  | JourneyMsg(PageJourney.msg)
  | ProfileMsg(PageProfile.msg)
  | SessionLoaded(Domain.session)
  | ApiError(string)

let initPage = (route: Route.t, session: option<Domain.session>): (page, Tea.Cmd.t<msg>) => {
  switch route {
  | Route.Home | Route.MoodInput =>
    let (model, cmd) = PageMoodInput.init()
    (MoodInputPage(model), Tea.Cmd.map(msg => MoodInputMsg(msg), cmd))

  | Route.RoutePlanner =>
    let (model, cmd) = PageRoutePlanner.init()
    (RoutePlannerPage(model), Tea.Cmd.map(msg => RoutePlannerMsg(msg), cmd))

  | Route.Journey(id) =>
    let (model, cmd) = PageJourney.init(id, session)
    (JourneyPage(model), Tea.Cmd.map(msg => JourneyMsg(msg), cmd))

  | Route.Profile =>
    let (model, cmd) = PageProfile.init(session)
    (ProfilePage(model), Tea.Cmd.map(msg => ProfileMsg(msg), cmd))

  | Route.NotFound =>
    (NotFoundPage(PageNotFound.init()), Tea.Cmd.none)
  }
}

let init = (location: Tea_navigation.Location.t): (model, Tea.Cmd.t<msg>) => {
  let route = Routing.fromLocation(location)
  let mockSession = Some({
    Domain.user: {
      id: "user-123",
      name: "Adventurer",
      badge: Domain.Initiate,
    },
    token: "mock-token",
  })

  let (page, pageCmd) = initPage(route, mockSession)

  ({route, page, session: mockSession}, pageCmd)
}

let update = (msg: msg, model: model): (model, Tea.Cmd.t<msg>) => {
  switch msg {
  | UrlChanged(location) =>
    let route = Routing.fromLocation(location)
    let (page, cmd) = initPage(route, model.session)
    ({...model, route, page}, cmd)

  | MoodInputMsg(pageMsg) =>
    switch model.page {
    | MoodInputPage(pageModel) =>
      let (newModel, cmd) = PageMoodInput.update(pageMsg, pageModel)
      ({...model, page: MoodInputPage(newModel)}, Tea.Cmd.map(m => MoodInputMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | RoutePlannerMsg(pageMsg) =>
    switch model.page {
    | RoutePlannerPage(pageModel) =>
      let (newModel, cmd) = PageRoutePlanner.update(pageMsg, pageModel)
      ({...model, page: RoutePlannerPage(newModel)}, Tea.Cmd.map(m => RoutePlannerMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | JourneyMsg(pageMsg) =>
    switch model.page {
    | JourneyPage(pageModel) =>
      let (newModel, cmd) = PageJourney.update(pageMsg, pageModel)
      ({...model, page: JourneyPage(newModel)}, Tea.Cmd.map(m => JourneyMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | ProfileMsg(pageMsg) =>
    switch model.page {
    | ProfilePage(pageModel) =>
      let (newModel, cmd) = PageProfile.update(pageMsg, pageModel)
      ({...model, page: ProfilePage(newModel)}, Tea.Cmd.map(m => ProfileMsg(m), cmd))
    | _ => (model, Tea.Cmd.none)
    }

  | SessionLoaded(session) =>
    ({...model, session: Some(session)}, Tea.Cmd.none)

  | ApiError(_) =>
    // TODO: handle errors
    (model, Tea.Cmd.none)
  }
}

let view = (model: model): Tea.Html.t<msg> => {
  // Delegate to page views
  switch model.page {
  | NotFoundPage(m) => PageNotFound.view(m)
  | MoodInputPage(m) => Tea.Html.map(msg => MoodInputMsg(msg), PageMoodInput.view(m))
  | RoutePlannerPage(m) => Tea.Html.map(msg => RoutePlannerMsg(msg), PageRoutePlanner.view(m))
  | JourneyPage(m) => Tea.Html.map(msg => JourneyMsg(msg), PageJourney.view(m))
  | ProfilePage(m) => Tea.Html.map(msg => ProfileMsg(msg), PageProfile.view(m))
  }
}

let subscriptions = (model: model): Tea.Sub.t<msg> => {
  switch model.page {
  | JourneyPage(m) => Tea.Sub.map(msg => JourneyMsg(msg), PageJourney.subscriptions(m))
  | _ => Tea.Sub.none
  }
}

// Application entry point
let main = Tea_navigation.navigationProgram(
  location => UrlChanged(location),
  {
    init: init,
    update: update,
    view: view,
    subscriptions: subscriptions,
    shutdown: _ => Tea.Cmd.none,
  },
)
```

### Step 4: Server Setup (server/)

**server/deno.json**
```json
{
  "name": "nafa-server",
  "version": "0.1.0",
  "tasks": {
    "dev": "deno run --watch --allow-net --allow-read src/Main.res.js",
    "build": "rescript build",
    "start": "deno run --allow-net --allow-read src/Main.res.js"
  },
  "imports": {
    "cadre-router": "jsr:@hyperpolymath/cadre-router@^0.1"
  }
}
```

**server/rescript.json**
```json
{
  "name": "nafa-server",
  "sources": [
    {"dir": "src", "subdirs": true},
    {"dir": "../shared/src", "subdirs": true}
  ],
  "package-specs": [{
    "module": "es6",
    "in-source": true
  }],
  "suffix": ".res.js"
}
```

**server/src/Main.res**
```rescript
// SPDX-License-Identifier: Apache-2.0

// Server entry point using cadre-router

// Note: This is a scaffold - actual implementation depends on
// cadre-router's current API surface

module Router = {
  // Placeholder for cadre-router integration
  // Actual binding depends on cadre-router exports
}

let port = 8000

let handler = (request: Request.t): Promise.t<Response.t> => {
  // Route matching and handler dispatch
  // This will use cadre-router's typed routing
  Promise.resolve(Response.make("NAFA API"))
}

// Server startup
Deno.serve({port: port}, handler)
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
- [ ] Implement Routing.res with fromLocation parser
- [ ] Implement Main.res with navigationProgram
- [ ] Port each Page module:
  - [ ] Page/MoodInput.res
  - [ ] Page/RoutePlanner.res
  - [ ] Page/Journey.res
  - [ ] Page/Profile.res
  - [ ] Page/NotFound.res
- [ ] Port Ports.elm → client/src/Ports.res

### Server Setup
- [ ] Create cadre-router bindings (or import if published)
- [ ] Implement API routes matching client expectations
- [ ] Set up middleware (auth, session)
- [ ] Configure CORS for local development

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

## Open Questions

1. **UI Library**: rescript-tea uses virtual DOM. Do we want:
   - Pure Tea.Html (like elm-html)
   - React integration for richer components
   - Hybrid approach

2. **cadre-router Publishing**: Is cadre-router on JSR/npm, or should we vendor it?

3. **CRDT State**: Do we want to use cadre-router's distributed state for real-time features (journey collaboration)?

---

## Timeline-Free Milestones

1. **Scaffold**: Directory structure + configs
2. **Types**: Shared domain types compiling
3. **Routing**: Client routing working with mock pages
4. **Pages**: All pages ported with static content
5. **API**: Server routes returning mock data
6. **Integration**: Client calling server, full flow
7. **Cleanup**: Elm removed, production-ready
