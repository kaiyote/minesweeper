import { Socket } from 'phoenix'

export default class Minesweeper {
  constructor () {
    this.socket = new Socket('/socket', {
      logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
    })
    this.socket.connect()

    this.channel = this.socket.channel('minesweeper:lobby', {})
    this.channel.join().receive('ok', () => console.log('join ok'))
    this.channel.onError(e => console.log('error: ', e))
    this.channel.onClose(e => console.log('channel closed', e))

    this.name = (new Date()).toISOString()
  }

  newGame (size) {
    return new Promise((resolve, reject) => this.channel.push('stop', { name: this.name })
      .receive('ok', () => {
        this.channel.push('new_game', { name: this.name, size })
          .receive('ok', response => { resolve(response.field) })
      }))
  }

  flag (x, y) {
    return new Promise((resolve, reject) => this.channel.push('flag', { name: this.name, x, y })
      .receive('ok', response => { resolve(response.field) }))
  }

  pick (x, y) {
    return new Promise((resolve, reject) => this.channel.push('pick', { name: this.name, x, y })
      .receive('ok', response => { resolve(response) }))
  }

  forcePick (x, y) {
    return new Promise((resolve, reject) => this.channel.push('force_pick', { name: this.name, x, y })
      .receive('ok', response => { resolve(response) }))
  }
}
