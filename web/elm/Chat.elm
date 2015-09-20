module Chat where

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (..)
import Json.Decode as Json
import Json.Decode exposing ((:=))
import Json.Encode exposing (null)
import Dict exposing (Dict)
import Time exposing (Time)


-- MODEL

type alias User =
  { uid : String
  , name : String
  , on : Bool
  }

initUser : User
initUser =
  { uid = ""
  , name = ""
  , on = False
  }

type alias Users = List User

userDecoder : Json.Decoder User
userDecoder =
  Json.object3 User
    ("uid" := Json.string)
    ("name" := Json.string)
    ("on" := Json.bool)

decodeUser : Json.Value -> Maybe User
decodeUser values =
  case (Json.decodeValue userDecoder values) of
    Ok user -> Just user
    _ -> Nothing

encodeUser : User -> Json.Value
encodeUser {uid, name, on} =
  Json.Encode.object
    [ ("uid", Json.Encode.string uid)
    , ("name", Json.Encode.string name)
    , ("on", Json.Encode.bool on)
    ]

usersDecoder : Json.Decoder Users
usersDecoder =
  Json.list userDecoder

decodeUsers : Json.Value -> Maybe Users
decodeUsers values =
  case (Json.decodeValue usersDecoder values) of
    Ok users -> Just users
    _ -> Nothing

type alias ChatMsg =
  { uid : String
  , msg : String
  -- , ts : Time
  }

type alias Event =
  { event : String
  , payload : Json.Value
  }

defaultEvent =
  { event = ""
  , payload = null
  }

type alias Model =
  { msgs : List ChatMsg
  , self : User
  , users : Dict String User
  , typing : String
  }

init : Model
init =
  { msgs = []
  , self = initUser
  , users = Dict.empty
  , typing = ""
  }


-- UPDATE

type ClientAction
  = CNoOp
  | UpdateSelf User

type ServerAction
  = SNoOp
  | Users Users
  | SelfUpdated User

update : ServerAction -> Model -> Model
update action model =
  case action of

    SNoOp ->
      model

    Users users ->
      let new_users =
        Dict.union (users |> List.map (\u -> (u.uid, u)) |> Dict.fromList) model.users
      in
        {model | users <- new_users}

    SelfUpdated self ->
      {model | self <- self}

    _ ->
      model


-- PORTS

port serverEvents : Signal Event

port clientEvents : Signal Event
port clientEvents =
  Signal.filterMap clientEvent defaultEvent clientActions.signal

clientEvent : ClientAction -> Maybe Event
clientEvent action =
  case action of
    UpdateSelf self -> Just {event = "self", payload = encodeUser self}
    _ -> Nothing

serverEvent : Event -> Maybe ServerAction
serverEvent {event, payload} =
  case event of
    "users" -> Maybe.map Users (decodeUsers payload)
    "self" -> Maybe.map SelfUpdated (decodeUser payload)
    _ -> Nothing


-- SIGNALS

main : Signal Html
main =
  Signal.map (view clientActions.address) model

model : Signal Model
model =
  Signal.foldp update init serverActions

clientActions : Signal.Mailbox ClientAction
clientActions =
  Signal.mailbox CNoOp

serverActions : Signal ServerAction
serverActions =
  Signal.filterMap serverEvent SNoOp serverEvents


-- VIEW

userList : List User -> Html
userList users =
  div []
    [ text "User List"
    , ul [] (List.map (\u -> li [] [text u.name]) (List.filterMap (\u -> if u.on then Just u else Nothing) users))
    ]

chatView : List ChatMsg -> Html
chatView msgs =
  div [] []

selfView : Address ClientAction -> User -> Html
selfView client self =
  div []
    [ input
      [ value self.name
      , on "blur" targetValue (Signal.message client << (\name -> UpdateSelf {self | name <- name}))
      ] []
    ]

inputView : Address ClientAction -> Model -> Html
inputView client model =
  div []
    [ selfView client model.self
    , div [] [ text model.typing ]
    ]

view : Address ClientAction -> Model -> Html
view client model =
  div []
    [ chatView model.msgs
    , inputView client model
    , model.users |> Dict.values |> userList
    ]
