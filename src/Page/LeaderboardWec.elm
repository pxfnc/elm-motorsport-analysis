module Page.LeaderboardWec exposing (Model, Msg, init, update, view)

import Data.Leaderboard as Leaderboard exposing (State, initialSort)
import Effect exposing (Effect)
import Html.Styled as Html exposing (Html, input, text)
import Html.Styled.Attributes as Attributes exposing (type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Motorsport.Analysis as Analysis
import Motorsport.Clock as Clock
import Motorsport.RaceControl as RaceControl
import Shared
import UI.Button exposing (button, labeledButton)
import UI.Label exposing (basicLabel)



-- MODEL


type alias Model =
    { tableState : State
    , query : String
    }


init : ( Model, Effect Msg )
init =
    ( { tableState = initialSort "Position"
      , query = ""
      }
    , Effect.fetchCsv "/static/23_Analysis_Race_Hour 24.csv"
    )



-- UPDATE


type Msg
    = RaceControlMsg RaceControl.Msg
    | SetTableState State


update : Msg -> Model -> ( Model, Effect Msg )
update msg m =
    case msg of
        RaceControlMsg raceControlMsg ->
            ( m, Effect.updateRaceControl raceControlMsg )

        SetTableState newState ->
            ( { m | tableState = newState }, Effect.none )



-- VIEW


view : Shared.Model -> Model -> List (Html Msg)
view { raceControl } { tableState } =
    let
        { raceClock, lapTotal, cars } =
            raceControl

        leaderboard =
            Leaderboard.init raceClock cars
    in
    [ input
        [ type_ "range"
        , Attributes.max <| String.fromInt lapTotal
        , value (String.fromInt raceClock.lapCount)
        , onInput (String.toInt >> Maybe.withDefault 0 >> RaceControl.SetCount >> RaceControlMsg)
        ]
        []
    , labeledButton []
        [ button [ onClick (RaceControlMsg RaceControl.PreviousLap) ] [ text "-" ]
        , basicLabel [] [ text (String.fromInt raceClock.lapCount) ]
        , button [ onClick (RaceControlMsg RaceControl.NextLap) ] [ text "+" ]
        ]
    , text <| Clock.toString raceClock
    , Leaderboard.view_ tableState
        raceClock
        (Analysis.fromRaceControl raceControl)
        SetTableState
        1.2
        leaderboard
    ]
