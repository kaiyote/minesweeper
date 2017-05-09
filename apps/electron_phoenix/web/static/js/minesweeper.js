import { Socket } from 'phoenix'

class Minesweeper {
  constructor () {
    this.socket = new Socket('/socket', {
      logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
    })
    this.socket.connect()

    this.channel = this.socket.channel('minesweeper:lobby', {})
    this.channel.join().receive('ok', () => console.log('join ok'))
    this.channel.onError(e => console.log('error: ', e))
    this.channel.onClose(e => console.log('channel closed', e))
  }

  newGame (size) {
    this.channel.push('new_game', { size })
      .receive('ok', response => {
        console.log(response)
      })
  }

  flag (x, y) {
    this.channel.push('flag', { x, y })
      .receive('ok', response => {
        console.log(response)
      })
  }
}

export default Minesweeper
