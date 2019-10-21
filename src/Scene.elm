module Scene exposing (main)

-- import Color
-- import Canvas
-- import Canvas.Settings
-- import Canvas.Settings.Advanced

import Browser exposing (Document)
import Browser.Navigation
import File
import File.Select
import Grid exposing (Dimension(..), addGridOffset, setGridSize, viewGrid)
import Html exposing (..)
import Html.Attributes exposing (class, id, multiple, size, src, style, type_)
import HtmlCommon exposing (layerDiv)
import Html.Events exposing (on, onClick)
import Json.Decode
import Http
import HttpCommon
import SceneMsg exposing (..)
import Task
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

--------------------------------------------------------------------------------
-- MODEL
--------------------------------------------------------------------------------
type alias GameScene =
    { game : String
    , scene : String
    }

type alias Model =
    { gameScene : GameScene
    , page : Page
    }

type Page
    = NoGame String
    | LoadingSceneJson
    | SceneRequestFailed String
    | SceneModel SceneData

type alias SceneData =
    { mapImage : String
    , tokens : List Token
    , grid : GridConfig
    , gridControls : GridState
    }

type alias Token =
    { size : Float -- a factor of grid.size
    , image : String
    }

type GridState
    = Hidden
    | ShowingNoControls
    | ShowingWithControls

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------
sceneJsonUrl : GameScene -> String
sceneJsonUrl gameScene =
    "game/" ++ gameScene.game ++ "/scene/" ++ gameScene.scene ++ "/scene.json"

init : flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    case (Url.Parser.parse gameSceneUrlParser url) of
        Nothing ->
            (Model (GameScene "???" "???") (NoGame "url parser failed?"), Cmd.none )
        Just maybeGameScene ->
            case maybeGameScene.maybeGame of
                Nothing ->
                    (Model (GameScene "???" "???") (NoGame "missing 'game' query parameter"), Cmd.none )
                Just game ->
                    case maybeGameScene.maybeScene of
                        Nothing ->
                            (Model (GameScene game "???") (NoGame "missing 'scene' query parameter"), Cmd.none )
                        Just scene ->
                            let
                                gameScene = (GameScene game scene)
                            in
                            ( Model gameScene LoadingSceneJson
                            , Http.get
                                { url = sceneJsonUrl gameScene
                                , expect = Http.expectJson GotScene sceneDecoder
                                }
                            )

sceneDecoder : Json.Decode.Decoder Scene
sceneDecoder =
    Json.Decode.map2 Scene
     (Json.Decode.field "mapImage" Json.Decode.string)
     (Json.Decode.field "grid"
         (Json.Decode.map5 GridConfig
             (Json.Decode.field "width" Json.Decode.int)
             (Json.Decode.field "height" Json.Decode.int)
             (Json.Decode.field "offsetX" Json.Decode.int)
             (Json.Decode.field "offsetY" Json.Decode.int)
             (Json.Decode.field "size" Json.Decode.int)
         ))

type alias MaybeGameScene =
    { maybeGame : Maybe String
    , maybeScene : Maybe String
    }

gameSceneUrlParser : Url.Parser.Parser (MaybeGameScene -> MaybeGameScene) (MaybeGameScene)
gameSceneUrlParser =
    Url.Parser.s "Scene.elm" <?> (Url.Parser.Query.map2 MaybeGameScene
        (Url.Parser.Query.string "game")
        (Url.Parser.Query.string "scene"))


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
        GotScene result ->
            case result of
                Ok scene ->
                    ( { model | page = SceneModel
                        (SceneData scene.mapImage [] scene.grid ShowingNoControls) }
                    , Cmd.none)
                Err error ->
                    ( { model | page = SceneRequestFailed (HttpCommon.httpErrorMsg error)}, Cmd.none )

        SelectedMapFile files ->
            ( model, Cmd.none )
--            let
--                fileNames =
--                    String.join ":" (List.map File.name files)
--            in
--            ( { scene | messages = model.messages ++ [ "selected map: " ++ fileNames ] }, Cmd.none )

        SceneMsg sceneMsg ->
            case model.page of
                NoGame _ ->
                    (model, Cmd.none)
                LoadingSceneJson ->
                    (model, Cmd.none)
                SceneRequestFailed _ ->
                    (model, Cmd.none)
                SceneModel sceneData ->
                    let
                        result = updateScene sceneMsg model sceneData
                    in
                    ( { model | page = (SceneModel (Tuple.first result)) }, (Tuple.second result))

--ignore msg model =
--    case model.page of
--
----        Starting ->
----            ( model, Cmd.none)
--
--        SceneModel scene ->
--            let
--                result = updateScene msg scene
--            in

--            , Tuple.second result
--            )

updateScene : SceneMsgType -> Model -> SceneData -> ( SceneData, Cmd Msg )
updateScene msg model scene =
    case msg of
        ShowGrid ->
            ( { scene | gridControls = ShowingNoControls }
            , Cmd.none
            )

        HideGrid ->
            ( { scene | gridControls = Hidden }
            , Cmd.none
            )

        ShowGridControls ->
            ( { scene | gridControls = ShowingWithControls }
            , Cmd.none
            )

        HideGridControls ->
            ( { scene | gridControls = ShowingNoControls }
            , Cmd.none
            )

        IncrementGridSize ->
            ( { scene
                | grid = (setGridSize scene.grid (scene.grid.size + 1))
              }
            , Cmd.none
            )

        DecrementGridSize ->
            ( { scene
                | grid = (setGridSize scene.grid (scene.grid.size - 1))
              }
            , Cmd.none
            )

        IncrementGridOffsetX ->
            ( { scene
                | grid = (addGridOffset scene.grid DimensionX 1)
              }
            , Cmd.none
            )

        DecrementGridOffsetX ->
            ( { scene
                | grid = (addGridOffset scene.grid DimensionX -1)
              }
            , Cmd.none
            )

        IncrementGridOffsetY ->
            ( { scene
                | grid = (addGridOffset scene.grid DimensionY 1)
              }
            , Cmd.none
            )

        DecrementGridOffsetY ->
            ( { scene
                | grid = (addGridOffset scene.grid DimensionY -1)
              }
            , Cmd.none
            )



--
-- boiler-plate setters
--

setMapImage r n =
    { r | mapImage = n }


setGridControls r n =
    { r | gridControls = n }


setGrid r n =
    { r | grid = n }



--------------------------------------------------------------------------------
-- SUBSCRIPTIONS
--------------------------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



--------------------------------------------------------------------------------
-- VIEW
--------------------------------------------------------------------------------
-- (File.Select.file ["image/jpeg", "image/png"] ChangeImage)


view : Model -> Document Msg
view model =
    case model.page of
        NoGame msg ->
            Document "Error - No Game and/or Scene Selected"
                [div [] [ text msg ]
                ]

        LoadingSceneJson ->
            Document ("Loading '" ++ model.gameScene.scene ++ "' scene...")
                [ div []
                    [ text ("Loading '" ++ model.gameScene.scene ++ "' scene...") ]]

        SceneRequestFailed error ->
            Document "Failed"
                [div [] [ text ("failed to load " ++ (sceneJsonUrl model.gameScene) ++ ": " ++ error) ]
                ]

        SceneModel scene ->
            Document "Scene" [viewScene scene]

viewScene : SceneData -> Html Msg
viewScene scene =
    div []
        ([ layerDiv []
            [ img
                [ style "position" "absolute"
                , style "top" "0"
                , style "display" "inline-block"
                , style "margin" "auto"
                , src scene.mapImage
                ]
                []
            ]
         , layerDiv []
            ([ input
                [ type_ "file"
                , multiple False
                , on "change" (Json.Decode.map SelectedMapFile filesDecoder)
                ]
                []
             ]
                ++ viewGridControls scene
                ++ [ div []
                       [ button [] [ text "Add Token" ]
                        ]
                   ]
            )
         ]
            ++ (case scene.gridControls of
                    Hidden ->
                        []

                    ShowingNoControls ->
                        [ viewGrid scene.grid ]

                    ShowingWithControls ->
                        [ viewGrid scene.grid ]
               )
        )


viewGridControls : SceneData -> List (Html Msg)
viewGridControls scene =
    case scene.gridControls of
        Hidden ->
            [ div [] [ button [ onClick (SceneMsg ShowGrid) ] [ text "Show Grid" ] ] ]

        ShowingNoControls ->
            [ div []
                [ button [ onClick (SceneMsg HideGrid) ] [ text "Hide Grid" ]
                , button [ onClick (SceneMsg ShowGridControls) ] [ text "Change Grid" ]
                ]
            ]

        ShowingWithControls ->
            [ div [ style "background" "green" ]
                [ button [ onClick (SceneMsg HideGridControls) ] [ text "X" ]
                , viewIntControl "Size" scene.grid.size (SceneMsg DecrementGridSize) (SceneMsg IncrementGridSize)
                , viewIntControl "X" scene.grid.offsetX (SceneMsg DecrementGridOffsetX) (SceneMsg IncrementGridOffsetX)
                , viewIntControl "Y" scene.grid.offsetY (SceneMsg DecrementGridOffsetY) (SceneMsg IncrementGridOffsetY)
                ]
            ]

viewIntControl : String -> Int -> Msg -> Msg -> Html Msg
viewIntControl name value decEvent incEvent =
    div []
        [ button [ onClick decEvent ] [ text "-" ]
        , button [ onClick incEvent ] [ text "+" ]
        , text (name ++ ": " ++ String.fromInt value)
        ]

viewportContentDiv : List (Html Msg) -> Html Msg
viewportContentDiv content =
    div
        [ id "ViewportDiv"
        , style "position" "fixed"
        , style "top" "0"
        , style "bottom" "0"
        , style "left" "0"
        , style "right" "0"
        , style "background" "blue"
        , style "overflow" "scroll"
        ]
        [ div
            [ class "ContentDiv"
            , style "background" "red"
            , style "position" "absolute"
            , style "top" "0"
            ]
            content
        ]


messageDiv : String -> Html Msg
messageDiv msg =
    div [] [ text msg ]


filesDecoder : Json.Decode.Decoder (List File.File)
filesDecoder =
    Json.Decode.at [ "target", "files" ] (Json.Decode.list File.decoder)
