import {Socket} from "deps/phoenix/web/static/js/phoenix"

class ChatClient {
  constructor() {
    this.socket = new Socket("/socket")
    this.socket.connect()
  }

  join(channel) {
    this.chan = this.socket.channel(channel, {})
    this.chan.join()
      .receive("ok", chan => {console.log("Welcome to Exchat!") })
      .receive("error", chan => {console.error("Channel join error") })
  }
}

let chat = new ChatClient()

let chatApp = Elm.fullscreen(Elm.Chat, {messages: {msg: ''}})

chat.join("rooms:lobby")

chatApp.ports.sendMsg.subscribe(msg => {
  chat.chan.push('say', {msg: msg})
})

chat.chan.on('say', payload => {
  chatApp.ports.messages.send(payload)
})
