module Chat where

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (Signal, Address)


-- MODEL

type alias ChatEvent = {msg : String}

type alias Model =
  { logs : List String
  , typing : String
  }

init : Model
init =
  { logs = []
  , typing = ""
  }


-- UPDATE

type Action
  = NoOp
  | Typing String
  | Send String
  | Receive ChatEvent

update : Action -> Model -> Model
update action model =
  case action of
    NoOp ->
      model
    Typing msg ->
      {model | typing <- msg}
    Send msg ->
      {model | typing <- ""}
    Receive event ->
      {model | logs <- List.append model.logs [event.msg]}


-- PORTS

port messages : Signal ChatEvent

port sendMsg : Signal String
port sendMsg =
  Signal.filterMap onlySendMsg "" clientActions.signal

onlySendMsg : Action -> Maybe String
onlySendMsg action =
  case action of
    Send msg -> Just msg
    _ -> Nothing


-- SIGNALS

main : Signal Html
main =
  Signal.map (view clientActions.address) model

model : Signal Model
model =
  Signal.foldp update init actions

actions : Signal Action
actions =
  Signal.merge clientActions.signal serverActions

clientActions : Signal.Mailbox Action
clientActions =
  Signal.mailbox NoOp

serverActions : Signal Action
serverActions =
  Signal.map (\event -> Receive event) messages


-- VIEW

view : Address Action -> Model -> Html
view address model =
  div []
    [ ol [] (List.map (\msg -> li [] [text msg]) model.logs)
    , input
      [ placeholder "Say something..."
      , autofocus True
      , value model.typing
      , on "input" targetValue (Signal.message address << Typing)
      , on "keypress" keyCode (\k ->
        if k == 13
          then Signal.message address (Send model.typing)
          else Signal.message address NoOp)
      ]
      []
    ]
