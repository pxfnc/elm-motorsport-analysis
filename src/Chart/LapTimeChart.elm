module Chart.LapTimeChart exposing (view)

import Axis
import Css exposing (block, cursor, default, display, hex, hover, none, property)
import Css.Global exposing (children, descendants, each, typeSelector)
import Data.Analysis exposing (Analysis, History)
import Data.Lap exposing (Lap, fastest)
import Html.Styled exposing (Html, fromUnstyled, text)
import Path.Styled as Path
import Scale exposing (ContinuousScale)
import Shape
import Svg.Styled exposing (Svg, circle, g, svg, text_)
import Svg.Styled.Attributes exposing (css, fill, stroke)
import TypedSvg.Styled.Attributes exposing (transform, viewBox)
import TypedSvg.Styled.Attributes.InPx exposing (cx, cy, r, x, y)
import TypedSvg.Types exposing (Transform(..))


w : Float
w =
    1000


h : Float
h =
    400


padding : { top : Float, right : Float, bottom : Float, left : Float }
padding =
    { top = 20, right = 20, bottom = 30, left = 60 }


xScale : Int -> ContinuousScale Float
xScale lapTotal =
    Scale.linear ( padding.left, w - padding.right ) ( 0, toFloat lapTotal )


yScale : Lap -> ContinuousScale Float
yScale fastestLap =
    Scale.linear ( h - padding.bottom, padding.top ) ( fastestLap.time, fastestLap.time * 1.2 )


xAxis : Int -> Svg msg
xAxis lapTotal =
    g
        [ transform [ Translate 0 (h - padding.bottom) ]
        , css
            [ descendants
                [ each [ typeSelector "line", typeSelector "path" ]
                    [ property "stroke" "#999" ]
                , typeSelector "text"
                    [ Css.fill (hex "#999") ]
                ]
            ]
        ]
        [ fromUnstyled <| Axis.bottom [] (xScale lapTotal) ]


yAxis : Lap -> Svg msg
yAxis fastestLap =
    g
        [ transform [ Translate padding.left 0 ]
        , css
            [ descendants
                [ each [ typeSelector "line", typeSelector "path" ]
                    [ property "stroke" "#999" ]
                , typeSelector "text"
                    [ Css.fill (hex "#999") ]
                ]
            ]
        ]
        [ fromUnstyled <| Axis.left [] (yScale fastestLap) ]


view : Analysis -> Html msg
view { summary, raceHistories } =
    let
        lapTotal =
            summary.lapTotal

        fastestLap =
            raceHistories
                |> List.filterMap (.laps >> fastest)
                |> fastest
                |> Maybe.withDefault (Lap 0 0 0)
    in
    svg [ viewBox 0 0 w h ]
        [ xAxis lapTotal
        , yAxis fastestLap
        , lapHistories
            { x = .lapCount >> toFloat >> Scale.convert (xScale lapTotal)
            , y = .time >> Scale.convert (yScale fastestLap)
            }
            raceHistories
        ]


lapHistories : { x : Lap -> Float, y : Lap -> Float } -> List History -> Svg msg
lapHistories options histories =
    g [] <|
        List.map
            (\history ->
                lapHistory
                    { x = options.x
                    , y = options.y
                    , dotLabel = .lapCount >> String.fromInt
                    , color = history.driver.teamColor
                    }
                    history.laps
            )
            histories


lapHistory :
    { x : a -> Float
    , y : a -> Float
    , dotLabel : a -> String
    , color : String
    }
    -> List a
    -> Svg msg
lapHistory options laps =
    g
        [ Svg.Styled.Attributes.class "history" ]
        [ path
            { x = options.x
            , y = options.y
            , strokeColor = options.color
            }
            laps
        , g [] <|
            List.map
                (dotWithLabel
                    { x = options.x
                    , y = options.y
                    , label = options.dotLabel
                    , fillColor = options.color
                    }
                )
                laps
        ]


dotWithLabel : { x : a -> Float, y : a -> Float, label : a -> String, fillColor : String } -> a -> Svg msg
dotWithLabel options item =
    g
        [ css
            [ children
                [ typeSelector "text"
                    [ display none, cursor default ]
                ]
            , hover
                [ children
                    [ typeSelector "text"
                        [ display block ]
                    ]
                ]
            ]
        ]
        [ circle
            [ cx (options.x item)
            , cy (options.y item)
            , r 2
            , fill options.fillColor
            , stroke "#fff"
            ]
            []
        , text_ [ x (options.x item), y (options.y item) ] [ text <| options.label item ]
        ]


path : { x : a -> Float, y : a -> Float, strokeColor : String } -> List a -> Svg msg
path { x, y, strokeColor } items =
    items
        |> List.map (\item -> Just ( x item, y item ))
        |> Shape.line Shape.linearCurve
        |> (\path_ -> Path.element path_ [ fill "none", stroke strokeColor ])
