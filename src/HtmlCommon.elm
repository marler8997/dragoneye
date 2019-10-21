module HtmlCommon exposing (layerDiv)

import Html exposing (Html, div)
import Html.Attributes exposing (class, style)

layerDiv : List (Html.Attribute a) -> List (Html a) -> Html a
layerDiv attrs content =
    div
        ([ class "LayerDiv"
        , style "position" "absolute"
        , style "top" "0"
        ] ++ attrs)
        content
