import Chat from "./chat"

let chat = new Chat()

let chatApp = Elm.fullscreen(Elm.Main, {messages: 'ExChat'})

chat.join("rooms:lobby")

chat.chan.on('msg', payload => {
  console.log(payload)
  chatApp.ports.messages.send(payload.msg)
})
