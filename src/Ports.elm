cat > elm-ui/src/Ports.elm << 'EOF'
port module Ports exposing
    ( Msg(..)
    , fromPorts
    , handleMsg
    , requestRoute
    , sendMoodLog
    , triggerHaptic
    )

{-| This module defines all ports for communication with JavaScript.
We use a single incoming port (`fromPorts`) with a tagged JSON
message to handle all inbound data, which is a robust pattern.

We use multiple outgoing ports for specific commands.
-}


import Json.Decode as Decode
import Main
import Types


-- OUTGOING PORTS (Elm -> JS)


port requestRoute : { from : String, to : String, profile : Types.SensoryProfile } -> Cmd msg
port sendMoodLog : Types.SensoryProfile -> Cmd msg
port triggerHaptic : { pattern : String, duration : Int } -> Cmd msg


-- INCOMING PORT (JS -> Elm)


port fromPorts : (Decode.Value -> msg) -> Sub msg


-- INCOMING MESSAGE HANDLING


type Msg
    = RouteReceived (Result Decode.Error (List Types.RouteSegment))
    | AmbientTrigger String
    | BadgeUnlocked Types.Badge


handleMsg : Msg -> Main.Model -> ( Main.Model, Cmd Main.Msg )
handleMsg msg model =
    -- This is where you would react to messages from the backend
    -- For example, update the RoutePlanner page when a route comes in
    case ( msg, model.page ) of
        ( RouteReceived (Ok segments), Main.RoutePlanner pageModel ) ->
            -- We received a route, so let's update the page model
            let
                ( newPageModel, pageCmd, navCmd ) =
                    Page.RoutePlanner.handleRouteSuccess segments pageModel
            in
            ( { model | page = Main.RoutePlanner newPageModel }
            , Cmd.batch [ Cmd.map Main.RoutePlannerMsg pageCmd, navCmd ]
            )

        ( RouteReceived (Err err), Main.RoutePlanner pageModel ) ->
            -- Handle the route error
            let
                ( newPageModel, pageCmd, navCmd ) =
                    Page.RoutePlanner.handleRouteError (Decode.errorToString err) pageModel
            in
            ( { model | page = Main.RoutePlanner newPageModel }
            , Cmd.batch [ Cmd.map Main.RoutePlannerMsg pageCmd, navCmd ]
            )

        ( AmbientTrigger triggerType, Main.Journey pageModel ) ->
            -- We got an ambient trigger (e.g., "Approaching loud zone")
            -- Let the Journey page handle it
            let
                ( newPageModel, pageCmd ) =
                    Page.Journey.handleAmbientTrigger triggerType pageModel
            in
            ( { model | page = Main.Journey newPageModel }
            , Cmd.map Main.JourneyMsg pageCmd
            )

        ( BadgeUnlocked newBadge, _ ) ->
            -- User unlocked a new badge! Update the session.
            let
                newSession =
                    { model.session
                        | user = { model.session.user | badge = newBadge }
                    }
            in
            ( { model | session = newSession }, Cmd.none )

        -- Ignore messages that don't match the current page
        _ ->
            ( model, Cmd.none )


-- DECODER for all incoming messages


decodeMsg : Decode.Decoder Msg
decodeMsg =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\tag ->
                case tag of
                    "route-received" ->
                        Decode.map RouteReceived (Decode.field "payload" (Decode.list Types.decodeRouteSegment))

                    "ambient-trigger" ->
                        Decode.map AmbientTrigger (Decode.field "payload" Decode.string)

                    "badge-unlocked" ->
                        Decode.map BadgeUnlocked (Decode.field "payload" Types.decodeBadge)

                    _ ->
                        Decode.fail ("Unknown port message type: " ++ tag)
            )
EOF