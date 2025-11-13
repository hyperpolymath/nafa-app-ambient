module Routing exposing (Route(..), fromUrl, toString)

import Url
import Url.Parser as Parser exposing ((</>), (<?>), Parser, int, s, string)


type Route
    = Home
    | MoodInput
    | RoutePlanner
    | Journey String -- By Journey ID
    | Profile
    | NotFound


fromUrl : Url.Url -> Route
fromUrl url =
    case Parser.parse routeParser url of
        Just route ->
            route

        Nothing ->
            NotFound


routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map MoodInput (s "mood")
        , Parser.map RoutePlanner (s "plan")
        , Parser.map Journey (s "journey" </> string)
        , Parser.map Profile (s "profile")
        ]


toString : Route -> String
toString route =
    case route of
        Home ->
            "/"

        MoodInput ->
            "/mood"

        RoutePlanner ->
            "/plan"

        Journey journeyId ->
            "/journey/" ++ journeyId

        Profile ->
            "/profile"

        NotFound ->
            "/404"