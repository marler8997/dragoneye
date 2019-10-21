module HttpCommon exposing (httpErrorMsg)

import Http

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
