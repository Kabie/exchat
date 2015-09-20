module Chat where

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (..)
import Json.Decode as Json
import Json.Decode exposing ((:=))
import Json.Encode exposing (null)
import Dict exposing (Dict)
import Either exposing (..)


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

encodeUser : User -> Json.Value
encodeUser {uid, name, on} =
  Json.Encode.object
    [ ("uid", Json.Encode.string uid)
    , ("name", Json.Encode.string name)
    , ("on", Json.Encode.bool on)
    ]

userDecoder : Json.Decoder User
userDecoder =
  Json.object3 User
    ("uid" := Json.string)
    ("name" := Json.string)
    ("on" := Json.bool)

decodeUser : Json.Value -> Maybe User
decodeUser value =
  case (Json.decodeValue userDecoder value) of
    Ok user -> Just user
    _ -> Nothing

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

encodeChatMsg : ChatMsg -> Json.Value
encodeChatMsg {uid, msg} =
  Json.Encode.object
    [ ("uid", Json.Encode.string uid)
    , ("msg", Json.Encode.string msg)
    ]

chatMsgDecoder : Json.Decoder ChatMsg
chatMsgDecoder =
  Json.object2 ChatMsg
    ("uid" := Json.string)
    ("msg" := Json.string)

decodeChatMsg : Json.Value -> Maybe ChatMsg
decodeChatMsg value =
  case (Json.decodeValue chatMsgDecoder value) of
    Ok chatMsg -> Just chatMsg
    _ -> Nothing

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
  | Typing String
  | Say ChatMsg

type ServerAction
  = SNoOp
  | Users Users
  | SelfUpdated User
  | Said ChatMsg

type alias Action = Either ClientAction ServerAction

update : Action -> Model -> Model
update action model =
  case action of
    Left clientAction ->
      case clientAction of
        CNoOp ->
          model

        Typing typing ->
          {model | typing <- typing}

        Say something ->
          {model | typing <- ""}

        _ ->
          model


    Right serverAction ->
      case serverAction of
        SNoOp ->
          model

        Users users ->
          let new_users =
            Dict.union (users |> List.map (\u -> (u.uid, u)) |> Dict.fromList) model.users
          in
            {model | users <- new_users}

        SelfUpdated self ->
          {model | self <- self}

        Said something ->
          {model | msgs <- something :: model.msgs}

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
    Say something -> Just {event = "say", payload = encodeChatMsg something}
    _ -> Nothing

serverEvent : Event -> Maybe ServerAction
serverEvent {event, payload} =
  case event of
    "users" -> Maybe.map Users (decodeUsers payload)
    "self" -> Maybe.map SelfUpdated (decodeUser payload)
    "said" -> Maybe.map Said (decodeChatMsg payload)
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
  Signal.merge (Left <~ clientActions.signal) (Right <~ serverActions)

clientActions : Signal.Mailbox ClientAction
clientActions =
  Signal.mailbox CNoOp

serverActions : Signal ServerAction
serverActions =
  Signal.filterMap serverEvent SNoOp serverEvents


-- VIEW

userList : Users -> Html
userList users =
  div []
    [ text "User List"
    , ul [] (List.map (\u -> li [] [text u.name]) (List.filterMap (\u -> if u.on then Just u else Nothing) users))
    ]

msgView : Dict String User -> ChatMsg -> Maybe Html
msgView users chat =
  users
  |> Dict.get chat.uid
  |> Maybe.map (\user ->
    div []
      [ text user.name
      , text " said: "
      , text chat.msg
      ])

chatView : Model -> Html
chatView model =
  div [] (List.filterMap (msgView model.users) model.msgs)

selfView : Address ClientAction -> User -> Html
selfView client self =
  div []
    [ input
      [ value self.name
      , on "blur" targetValue (Signal.message client << (\name ->
        if name == self.name
          then CNoOp
          else UpdateSelf {self | name <- name}))
      ] []
    ]

inputView : Address ClientAction -> Model -> Html
inputView client model =
  div []
    [ selfView client model.self
    , input
      [ placeholder "Say something..."
      , autofocus True
      , value model.typing
      , on "input" targetValue (Signal.message client << Typing)
      , onKeyPress client (\k ->
        if k == 13
          then Say {uid = model.self.uid, msg = model.typing}
          else CNoOp)
      ] []
    ]

view : Address ClientAction -> Model -> Html
view client model =
  div []
    [ chatView model
    , inputView client model
    , model.users |> Dict.values |> userList
    ]
