module Motorsport.Clock exposing
    ( Model(..), init
    , Msg(..), update
    , toString
    , Clock
    , calcElapsed
    )

{-|

@docs Model, init
@docs Msg, update
@docs toString

@docs Clock

-}

import Motorsport.Duration as Duration exposing (Duration)
import Time exposing (Posix, posixToMillis)


type Model
    = Initial
    | Started Duration { now : Posix, startedAt : Posix }
    | Paused Duration
    | Finished


init : Model
init =
    Initial


type Msg
    = Start
    | Tick
    | Pause
    | Finish


update : Posix -> Msg -> Model -> Model
update now msg m =
    case msg of
        Start ->
            case m of
                Initial ->
                    Started 0 { now = now, startedAt = now }

                Paused splitTime ->
                    Started splitTime { now = now, startedAt = now }

                _ ->
                    m

        Tick ->
            case m of
                Started splitTime posix ->
                    Started splitTime { posix | now = now }

                _ ->
                    m

        Pause ->
            case m of
                Started splitTime { startedAt } ->
                    Paused (calcElapsed startedAt now splitTime)

                _ ->
                    m

        Finish ->
            Finished


toString : Model -> String
toString m =
    case m of
        Initial ->
            "00:00:00"

        Started splitTime { now, startedAt } ->
            calcElapsed startedAt now splitTime
                |> (Duration.toString >> String.dropRight 4)

        Paused splitTime ->
            (Duration.toString >> String.dropRight 4) splitTime

        Finished ->
            "00:00:00"



-- HELPERS


diff : Posix -> Posix -> Int
diff a b =
    posixToMillis b - posixToMillis a


calcElapsed : Posix -> Posix -> Duration -> Int
calcElapsed startedAt now splitTime =
    let
        speed =
            10
    in
    (diff startedAt now * speed) + splitTime



-- OUTDATED


type alias Clock =
    { elapsed : Duration }
