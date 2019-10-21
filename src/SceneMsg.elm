module SceneMsg exposing (..)

import Browser
import File
import Http
import Url

type alias GridConfig =
    { width : Int
    , height: Int
    , offsetX : Int
    , offsetY : Int
    , size : Int
    }

type alias Scene =
    { mapImage : String
    , grid : GridConfig
    }

type SceneMsgType
    = ShowGrid
    | HideGrid
    | ShowGridControls
    | HideGridControls
    | IncrementGridSize
    | DecrementGridSize
    | IncrementGridOffsetX
    | DecrementGridOffsetX
    | IncrementGridOffsetY
    | DecrementGridOffsetY

type Msg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url.Url
    | GotScene (Result Http.Error Scene)
--    | ChangeImage String
    | SelectedMapFile (List File.File)
    | SceneMsg SceneMsgType
