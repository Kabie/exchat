import {Socket} from "deps/phoenix/web/static/js/phoenix"

class Chat {
  constructor() {
    this.socket = new Socket("/socket")
    this.chan = this.socket.channel("rooms:lobby", {})
    this.chan.join()
      .receive("ok", chan => {console.log("Welcome to Phoenix Chat!") })
      .receive("error", chan => {console.error("Channel join error") })
  }

  connect() {
    this.socket.connect()
  }
}

export default Chat
