module Game exposing (main)

import Array
import Browser exposing (UrlRequest, Document)
import Browser.Navigation
--import File
--import File.Select
--import Grid exposing (Dimension(..), GridConfig, addGridOffset, setGridSize, viewGrid)
import Html exposing (Html, div, text, h1)
import Html.Attributes exposing (href)
--import Html.Events exposing (on, onClick)
import HttpCommon
import Json.Decode
import Http
import Url exposing (Url)
import Url.Parser exposing (query, (<?>) )
import Url.Parser.Query

main : Program String Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChange
        , onUrlRequest = UrlRequest
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type Msg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url
    | GotScenes (Result Http.Error (Array.Array String))

--------------------------------------------------------------------------------
-- MODEL
--------------------------------------------------------------------------------

type alias Model =
    { game : String
    , page : Page
    }

type Page
    = NoGame String
    | LoadingScenesJson
    | SceneRequestFailed String
    | SelectGame (Array.Array String)

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------
scenesJsonUrl : String -> String
scenesJsonUrl game =
    "service/listdir?path=game/" ++ game ++ "/scene"

init : flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    case (Url.Parser.parse gameUrlParser url) of
        Nothing ->
            (Model "???" (NoGame "url parser failed?"), Cmd.none )
        Just maybeGame ->
            case maybeGame of
                Nothing ->
                    (Model "???" (NoGame "missing 'game' query parameter"), Cmd.none )
                Just game ->
                    let
                        gameUrl = scenesJsonUrl game
                    in
                    ( Model game LoadingScenesJson
                    , Http.get
                        { url = gameUrl
                        , expect = Http.expectJson GotScenes scenesDecoder
                        }
                    )


gameUrlParser : Url.Parser.Parser (Maybe String -> Maybe String) (Maybe String)
gameUrlParser =
    Url.Parser.s "Game.elm" <?> Url.Parser.Query.string "game"

scenesDecoder : Json.Decode.Decoder (Array.Array String)
scenesDecoder =
    Json.Decode.field "dirs" (Json.Decode.array Json.Decode.string)


--------------------------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------------------------
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange url ->
           (model, Browser.Navigation.load (Url.toString url))
        UrlRequest request ->
           case request of
               Browser.Internal url ->
                   (model, Browser.Navigation.load (Url.toString url))
               Browser.External url ->
                   (model, Browser.Navigation.load url)
        GotScenes gamesResult ->
            case gamesResult of
                Ok games ->
                    ( { model | page = SelectGame games}, Cmd.none )
                Err error ->
                    ( { model | page = SceneRequestFailed (HttpCommon.httpErrorMsg error)}, Cmd.none )

--------------------------------------------------------------------------------
-- SUBSCRIPTIONS
--------------------------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



--------------------------------------------------------------------------------
-- VIEW
--------------------------------------------------------------------------------

view : Model -> Document Msg
view model =
    case model.page of
        NoGame msg ->
            Document "Error - No Game Selected"
                [div [] [ text msg ]
                ]

        LoadingScenesJson ->
            Document "Loading..."
                [div [] [ text ("Loading " ++ (scenesJsonUrl model.game)) ]
                ]

        SceneRequestFailed error ->
            Document "Failed"
                [div [] [ text ("failed to load " ++ (scenesJsonUrl model.game) ++ ": " ++ error) ]
                ]

        SelectGame games ->
            Document (model.game ++ " - scene select")
                [ h1 [] [ text "Select a Scene" ]
                , div [] (Array.toList (Array.map (stringToDiv model.game) games))
                ]


stringToDiv : String -> String -> Html Msg
stringToDiv game scene =
    div []
        [ h1 [] [Html.a [href ("Scene.elm?game=" ++ game ++ "&scene=" ++ scene)] [text scene]]]
        --[ Html.a [href ("Scene.elm?game=" ++ game ++ "&scene=" ++ scene)] [text scene]]
