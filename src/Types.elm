cat > elm-ui/src/Types.elm << 'EOF'
module Types exposing (..)

import Json.Decode as Decode


-- SESSION & USER


type alias Session =
    { user : User
    , token : String
    }


type alias User =
    { id : String
    , name : String
    , badge : Badge
    }


type Badge
    = Initiate
    | Curator
    | Guardian
    | Companion


-- SENSORY & JOURNEY


type alias SensoryProfile =
    { noise : Int -- e.g., 0-10
    , light : Int
    , crowd : Int
    }


type alias RouteSegment =
    { transportType : String -- "walk", "bus", "train"
    , description : String -- "Walk to Stop B", "Take 42 Bus"
    , sensoryWarning : Maybe String -- "Loud intersection"
    , durationMinutes : Int
    }


-- JSON DECODERS


decodeUser : Decode.Decoder User
decodeUser =
    Decode.map3 User
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "badge" decodeBadge)


decodeBadge : Decode.Decoder Badge
decodeBadge =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "initiate" ->
                        Decode.succeed Initiate

                    "curator" ->
                        Decode.succeed Curator

                    "guardian" ->
                        Decode.succeed Guardian

                    "companion" ->
                        Decode.succeed Companion

                    _ ->
                        Decode.fail "Unknown badge type"
            )


decodeRouteSegment : Decode.Decoder RouteSegment
decodeRouteSegment =
    Decode.map4 RouteSegment
        (Decode.field "transport_type" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "sensory_warning" (Decode.maybe Decode.string))
        (Decode.field "duration_minutes" Decode.int)
EOF