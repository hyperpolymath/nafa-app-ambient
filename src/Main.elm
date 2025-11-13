
module Main exposing (main)

import Api
import Browser
import Browser.Navigation as Nav
import Element
import Page.Journey
import Page.MoodInput
import Page.NotFound
import Page.Profile
import Page.RoutePlanner
import Ports
import Routing
import Types
import Url


-- MODEL


type alias Model =
    { navKey : Nav.Key
    , session : Types.Session
    , route : Routing.Route
    , page : Page
    }


type Page
    = NotFound Page.NotFound.Model
    | MoodInput Page.MoodInput.Model
    | RoutePlanner Page.RoutePlanner.Model
    | Journey Page.Journey.Model
    | Profile Page.Profile.Model


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }


init : flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    -- For this example, we start with a mock session
    -- In a real app, this would be `NoSession` and init
    -- would trigger a `Api.getSession` command.
    let
        mockSession =
            { user =
                { id = "user-123"
                , name = "Adventurer"
                , badge = Types.Initiate
                }
            , token = "mock-token"
            }

        ( route, page, pageCmd ) =
            changeRoute (Routing.fromUrl url) mockSession
    in
    ( Model navKey mockSession route page, pageCmd )



-- UPDATE


type Msg
    = OnUrlChange Url.Url
    | OnUrlRequest Browser.UrlRequest
    -- Page-specific messages
    | MoodInputMsg Page.MoodInput.Msg
    | RoutePlannerMsg Page.RoutePlanner.Msg
    | JourneyMsg Page.Journey.Msg
    | ProfileMsg Page.Profile.Msg
    -- Port messages
    | FromPorts Ports.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnUrlChange url ->
            let
                ( newRoute, newPage, pageCmd ) =
                    changeRoute (Routing.fromUrl url) model.session
            in
            ( { model | route = newRoute, page = newPage }
            , pageCmd
            )

        OnUrlRequest urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        -- Handle messages from ports
        FromPorts portMsg ->
            Ports.handleMsg portMsg model

        -- Delegate page-specific messages
        MoodInputMsg pageMsg ->
            case model.page of
                MoodInput pageModel ->
                    let
                        ( newPageModel, pageCmd, navCmd ) =
                            Page.MoodInput.update pageMsg pageModel
                    in
                    ( { model | page = MoodInput newPageModel }
                    , Cmd.batch [ Cmd.map MoodInputMsg pageCmd, navCmd ]
                    )

                _ ->
                    ( model, Cmd.none )

        RoutePlannerMsg pageMsg ->
            case model.page of
                RoutePlanner pageModel ->
                    let
                        ( newPageModel, pageCmd, navCmd ) =
                            Page.RoutePlanner.update pageMsg pageModel
                    in
                    ( { model | page = RoutePlanner newPageModel }
                    , Cmd.batch [ Cmd.map RoutePlannerMsg pageCmd, navCmd ]
                    )

                _ ->
                    ( model, Cmd.none )

        JourneyMsg pageMsg ->
            case model.page of
                Journey pageModel ->
                    let
                        ( newPageModel, pageCmd ) =
                            Page.Journey.update pageMsg pageModel
                    in
                    ( { model | page = Journey newPageModel }
                    , Cmd.map JourneyMsg pageCmd
                    )

                _ ->
                    ( model, Cmd.none )

        ProfileMsg pageMsg ->
            case model.page of
                Profile pageModel ->
                    let
                        ( newPageModel, pageCmd ) =
                            Page.Profile.update pageMsg pageModel
                    in
                    ( { model | page = Profile newPageModel }
                    , Cmd.map ProfileMsg pageCmd
                    )

                _ ->
                    ( model, Cmd.none )


changeRoute : Routing.Route -> Types.Session -> ( Routing.Route, Page, Cmd Msg )
changeRoute route session =
    case route of
        Routing.Home ->
            ( route, MoodInput Page.MoodInput.init, Cmd.none )

        Routing.MoodInput ->
            ( route, MoodInput Page.MoodInput.init, Cmd.none )

        Routing.RoutePlanner ->
            ( route, RoutePlanner Page.RoutePlanner.init, Cmd.none )

        Routing.Journey journeyId ->
            let
                ( pageModel, pageCmd ) =
                    Page.Journey.init session journeyId
            in
            ( route, Journey pageModel, Cmd.map JourneyMsg pageCmd )

        Routing.Profile ->
            let
                ( pageModel, pageCmd ) =
                    Page.Profile.init session
            in
            ( route, Profile pageModel, Cmd.map ProfileMsg pageCmd )

        Routing.NotFound ->
            ( route, NotFound Page.NotFound.init, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ -- Listen for messages from JavaScript/Elixir
          Ports.fromPorts FromPorts

        -- Delegate page-specific subscriptions
        , case model.page of
            Journey pageModel ->
                Sub.map JourneyMsg (Page.Journey.subscriptions pageModel)

            _ ->
                Sub.none
        ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        pageView =
            case model.page of
                NotFound pageModel ->
                    Page.NotFound.view pageModel
                        |> Element.map (\_ -> MoodInputMsg Page.MoodInput.NoOp) -- Placeholder

                MoodInput pageModel ->
                    Page.MoodInput.view pageModel
                        |> Element.map MoodInputMsg

                RoutePlanner pageModel ->
                    Page.RoutePlanner.view pageModel
                        |> Element.map RoutePlannerMsg

                Journey pageModel ->
                    Page.Journey.view pageModel
                        |> Element.map JourneyMsg

                Profile pageModel ->
                    Page.Profile.view pageModel
                        |> Element.map ProfileMsg

        -- Main layout
        layout =
            Element.layout
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.Font.family
                    [ Element.Font.sansSerif
                    , Element.Font.fallback "Inter"
                    ]
                ]
                pageView
    in
    { title = "NAFA - Neurodiverse App for Adventurers"
    , body = [ layout ]
    }