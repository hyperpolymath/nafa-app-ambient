// SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 hyperpolymath

/// Sensory intensity level (0-10 scale)
type sensoryLevel = int

/// User's sensory sensitivity profile
type sensoryProfile = {
  noise: sensoryLevel,
  light: sensoryLevel,
  crowd: sensoryLevel,
}

/// A sensory annotation for a specific location
type sensoryAnnotation = {
  id: string,
  locationId: string,
  locationName: string,
  noise: sensoryLevel,
  light: sensoryLevel,
  crowd: sensoryLevel,
  notes: option<string>,
  timestamp: float,
}

/// Transport mode for a journey segment
type transportMode =
  | Walk
  | Bus
  | Train
  | Tram
  | Metro

/// A single segment of a journey
type journeySegment = {
  id: string,
  transportMode: transportMode,
  fromLocation: string,
  toLocation: string,
  durationMinutes: int,
  sensoryWarning: option<string>,
  sensoryLevels: option<sensoryProfile>,
}

/// Status of a journey
type journeyStatus =
  | Planning
  | Active
  | Paused
  | Completed

/// A complete journey plan
type journey = {
  id: string,
  title: string,
  segments: array<journeySegment>,
  status: journeyStatus,
  estimatedMinutes: int,
  sensoryAnnotations: array<sensoryAnnotation>,
}

/// Convert transport mode to display string
let transportModeToString = (mode: transportMode): string => {
  switch mode {
  | Walk => "Walk"
  | Bus => "Bus"
  | Train => "Train"
  | Tram => "Tram"
  | Metro => "Metro"
  }
}

/// Convert transport mode to emoji for visual clarity
let transportModeToEmoji = (mode: transportMode): string => {
  switch mode {
  | Walk => "🚶"
  | Bus => "🚌"
  | Train => "🚆"
  | Tram => "🚊"
  | Metro => "🚇"
  }
}

/// Get sensory level description
let sensoryLevelDescription = (level: sensoryLevel): string => {
  if level <= 2 {
    "Very Low"
  } else if level <= 4 {
    "Low"
  } else if level <= 6 {
    "Moderate"
  } else if level <= 8 {
    "High"
  } else {
    "Very High"
  }
}

/// Check if sensory levels exceed user's profile tolerance
let exceedsProfile = (levels: sensoryProfile, profile: sensoryProfile): bool => {
  levels.noise > profile.noise || levels.light > profile.light || levels.crowd > profile.crowd
}
