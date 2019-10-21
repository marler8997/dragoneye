module DragonEye exposing (main)

import Array
import Browser
--import File
--import File.Select
--import Grid exposing (Dimension(..), GridConfig, addGridOffset, setGridSize, viewGrid)
import Html exposing (Html, div, text, h1, img)
import Html.Attributes exposing (href, style, src)
import HtmlCommon exposing (layerDiv)
--import Html.Events exposing (on, onClick)
import Json.Decode
import Http


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GotGames (Result Http.Error (Array.Array String))

--------------------------------------------------------------------------------
-- MODEL
--------------------------------------------------------------------------------

type Model
    = Loading
    | GamesRequestFailed String
    | SelectGame (Array.Array String)

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------
gamesJsonUrl =
    "service/listdir?path=game"

init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Http.get
        { url = gamesJsonUrl
        , expect = Http.expectJson GotGames gamesDecoder
        }
    )

gamesDecoder : Json.Decode.Decoder (Array.Array String)
gamesDecoder =
    Json.Decode.field "dirs" (Json.Decode.array Json.Decode.string)


--------------------------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------------------------
httpErrorMsg : Http.Error -> String
httpErrorMsg error =
    case error of
        Http.BadUrl url ->
            "invalid url: " ++ url
        Http.Timeout ->
            "timeout"
        Http.NetworkError ->
            "network error"
        Http.BadStatus status ->
            "HTTP error status: " ++ String.fromInt(status)
        Http.BadBody msg ->
            "HTTP sent invalid content: " ++ msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGames gamesResult ->
            case gamesResult of
                Ok games ->
                    ( SelectGame games, Cmd.none )
                Err error ->
                    ( GamesRequestFailed (httpErrorMsg error), Cmd.none )

--------------------------------------------------------------------------------
-- SUBSCRIPTIONS
--------------------------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



--------------------------------------------------------------------------------
-- VIEW
--------------------------------------------------------------------------------

view : Model -> Html Msg
view model =
    case model of
        Loading ->
            viewPage
                [div [] [ text "Loading Games..." ]
                ]

        GamesRequestFailed error ->
            viewPage
                [div [] [ text error ]
                ]

        SelectGame games ->
            viewPage
                [div [] (
                    [ h1 [] [ text "Select Game:" ]
                    ] ++ (Array.toList (Array.map viewGameSelect games)))
                ]

viewPage : List (Html Msg) -> Html Msg
viewPage content =
    div []
        [ layerDiv []
            [ img [src "pic/dragonfight.jpg"] []
            ]
        , div
            [ style "margin" "auto"
            , style "position" "relative"
            , style "top" "100px"
            , style "text-align" "center"
            ]
            [div []
                [ img [src "pic/dragoneye-logo.png"] []
                 , div
                     [ style "max-width" "500px"
                     , style "position" "relative"
                     , style "margin" "auto"
                     , style "background" "rgba(0,0,0,.6)"
                     , style "padding" "40px 10px"
                     , style "border" "2px solid #000"
                     ]
                     content
                ]
            ]
        ]


viewGameSelect : String -> Html Msg
viewGameSelect s =
    div [ style "margin" "20px"
        ]
        [ h1 [] [Html.a [href ("Game.elm?game=" ++ s)] [text s]]
        ]

