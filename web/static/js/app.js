import {Socket} from "deps/phoenix/web/static/js/phoenix"

class ChatClient {
  constructor() {
    this.socket = new Socket("/socket")
    this.socket.connect()
  }

  join(channel, params = {}, callback) {
    this.chan = this.socket.channel(channel, params)
    this.chan.join()
      .receive("ok", callback)
      .receive("error", chan => {console.error("Channel join error") })
  }
}

let chat = new ChatClient()

chat.join("rooms:lobby", {}, () => {
  let chatApp = Elm.fullscreen(Elm.Chat, {serverEvents: {event: '', payload: {}}})

  chatApp.ports.clientEvents.subscribe(({event, payload}) => {
    console.log(event, payload)
    chat.chan.push(event, payload)
  })

  chat.chan.on('say', payload => {
    console.log(payload)
    // chatApp.ports.messages.send(payload)
  })

  chat.chan.on('users', ({users}) => {
    console.log(users)
    chatApp.ports.serverEvents.send({event: 'users', payload: users})
  })

  chat.chan.on('self', (user) => {
    console.log(user)
    chatApp.ports.serverEvents.send({event: 'self', payload: user})
  })

})
