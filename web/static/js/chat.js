import {Socket} from "deps/phoenix/web/static/js/phoenix"

class Chat {
  constructor() {
    this.socket = new Socket("/socket")
    this.socket.connect()
  }

  join(channel) {
    this.chan = this.socket.channel(channel, {})
    this.chan.join()
      .receive("ok", chan => {console.log("Welcome to Phoenix Chat!") })
      .receive("error", chan => {console.error("Channel join error") })
  }
}

export default Chat
