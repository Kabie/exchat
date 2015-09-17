module Main where

import Html exposing (..)


-- MODEL

type alias Model =
  String


init : Model
init =
  "Hello Elm!"


-- UPDATE

type Action
  = NoOp

update : Action -> Model -> Model
update action model =
  case action of
    NoOp ->
      model


-- PORTS

port messages : Signal String


-- SIGNALS

main : Signal Html
main =
  Signal.map view model


model : Signal Model
model =
  --Signal.foldp update init actions.signal
  messages


actions : Signal.Mailbox Action
actions =
  Signal.mailbox NoOp


-- VIEW

view : Model -> Html
view model =
  text model
