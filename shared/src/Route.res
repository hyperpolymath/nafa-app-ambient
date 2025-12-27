// SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 hyperpolymath

/// Application routes
type t =
  | Home
  | JourneyView(string)
  | JourneyList
  | Annotate(string)
  | NotFound

/// Parse URL path to route
let fromPath = (path: string): t => {
  let segments =
    path
    ->String.split("/")
    ->Array.filter(s => s != "")

  switch segments {
  | [] => Home
  | ["journeys"] => JourneyList
  | ["journey", id] => JourneyView(id)
  | ["annotate", locationId] => Annotate(locationId)
  | _ => NotFound
  }
}

/// Convert route to URL path
let toPath = (route: t): string => {
  switch route {
  | Home => "/"
  | JourneyList => "/journeys"
  | JourneyView(id) => "/journey/" ++ id
  | Annotate(locationId) => "/annotate/" ++ locationId
  | NotFound => "/404"
  }
}
