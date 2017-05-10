import React from 'react'
import Counter from './controls/counter'
import Timer from './controls/timer'

export default class App extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      field: undefined,
      smiley: 'neutral',
      size: 'large'
    }
  }
  render () {
    return <div className='container'>
      <div className='title'>Minesweeper</div>
      <div className='mineField'>
        <div className='statusRow'>
          <Counter value='10' />
          <div className={'smiley-' + this.state.smiley}
            onMouseDown={e => this.poke()} onMouseUp={e => this.reset()}
            onClick={e => this.newGame(this.state.size)} />
          <Timer ref={t => { this.timer = t }} value='0' />
        </div>
        <div className='field' onClick={e => this.timer.start()}
          onMouseDown={e => this.shock()} onMouseUp={e => this.reset()}>
          HI MOM
        </div>
      </div>
    </div>
  }

  reset () {
    this.setState({ smiley: 'neutral' })
  }

  shock () {
    this.setState({ smiley: 'shocked' })
  }

  poke () {
    this.setState({ smiley: 'neutral-pressed' })
  }

  newGame (size) {

  }
}
