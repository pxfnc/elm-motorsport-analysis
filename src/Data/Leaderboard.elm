module Data.Leaderboard exposing
    ( Leaderboard
    , empty, init
    , view
    )

{-|

@docs Leaderboard
@docs empty, init
@docs view

-}

import Data.Leaderboard.Type
import Data.Leaderboard.View
import Html.Styled as Html exposing (Html)
import Motorsport.Car exposing (Car)
import Motorsport.Clock exposing (Clock)
import Motorsport.Duration exposing (Duration)
import Motorsport.Gap as Gap exposing (Gap(..))
import Motorsport.Lap exposing (completedLapsAt, findLastLapAt)
import UI.SortableData exposing (State)


type alias Leaderboard =
    Data.Leaderboard.Type.Leaderboard


empty : Leaderboard
empty =
    []


init : Clock -> List Car -> Leaderboard
init raceClock cars =
    let
        sortedCars =
            cars
                |> List.map
                    (\{ laps } ->
                        let
                            lastLap =
                                findLastLapAt raceClock laps
                                    |> Maybe.withDefault { carNumber = "", driver = "", lap = 0, time = 0, best = 0, elapsed = 0 }
                        in
                        { laps = laps, lap = lastLap }
                    )
                |> List.sortWith
                    (\a b ->
                        case compare a.lap.lap b.lap.lap of
                            LT ->
                                GT

                            EQ ->
                                case compare a.lap.elapsed b.lap.elapsed of
                                    LT ->
                                        LT

                                    EQ ->
                                        EQ

                                    GT ->
                                        GT

                            GT ->
                                LT
                    )
    in
    sortedCars
        |> List.indexedMap
            (\index { laps, lap } ->
                let
                    { carNumber, driver } =
                        List.head laps
                            |> Maybe.map (\l -> { carNumber = l.carNumber, driver = l.driver })
                            |> Maybe.withDefault { carNumber = "000", driver = "" }
                in
                { position = index + 1
                , driver = driver
                , carNumber = carNumber
                , lap = lap.lap
                , gap =
                    List.head sortedCars
                        |> Maybe.map (\leader -> Gap.from leader.lap lap)
                        |> Maybe.withDefault None
                , time = lap.time
                , best = lap.best
                , history = completedLapsAt raceClock laps
                }
            )


view : State -> Clock -> { fastestLapTime : Duration, slowestLapTime : Duration } -> (State -> msg) -> Float -> Leaderboard -> Html msg
view =
    Data.Leaderboard.View.view
