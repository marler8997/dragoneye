module Grid exposing (viewGrid, setGridSize, addGridOffset, Dimension(..))

import SceneMsg exposing (GridConfig, Msg)
import Html exposing (Html)
import Svg exposing (circle, line, rect, svg)
import Svg.Attributes exposing (cx, cy, height, r, rx, ry, style, viewBox, width, x, x1, x2, y, y1, y2)


setGridSize : GridConfig -> Int -> GridConfig
setGridSize grid newSize =
    { grid |
      size = newSize
    , offsetX = modBy newSize grid.offsetX
    , offsetY = modBy newSize grid.offsetY
    }

type Dimension = DimensionX | DimensionY

addGridOffset : GridConfig -> Dimension -> Int -> GridConfig
addGridOffset grid dim diff =
     case dim of
         DimensionX ->
             { grid | offsetX = modBy grid.size (grid.offsetX + diff) }
         DimensionY ->
             { grid | offsetY = modBy grid.size (grid.offsetY + diff) }

viewGrid : GridConfig -> Html Msg
viewGrid grid =
    svg
        [ width "800"
        , height "600"
        , viewBox "0 0 800 600"
        , style (  " stroke:rgb(200,200,200);stroke-opacity:.3;stroke-width:1"
                ++ ";pointer-events: none;position:absolute;top:0")
        ]
        (List.map (horizontalLine grid.offsetY grid.size) (List.range 0 (lineCount grid.height grid.size))
            ++ List.map (verticalLine grid.offsetX grid.size) (List.range 0 (lineCount grid.width grid.size))
        )

lineCount : Int -> Int -> Int
lineCount dim size =
    floor(toFloat(dim) / toFloat(size))

horizontalLine offset gridSize index =
    let
        yValue =
            String.fromInt (offset + gridSize * index)
    in
    line [ x1 "0", y1 yValue, x2 "800", y2 yValue ] []


verticalLine offset gridSize index =
    let
        xValue =
            String.fromInt (offset + gridSize * index)
    in
    line [ x1 xValue, y1 "0", x2 xValue, y2 "600" ] []
