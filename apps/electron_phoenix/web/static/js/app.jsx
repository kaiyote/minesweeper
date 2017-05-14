import React from 'react'
import Counter from './controls/counter'
import Timer from './controls/timer'
import NewGame from './controls/new_game'
import Minesweeper from './minesweeper'

export default class App extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      field: undefined,
      smiley: 'neutral',
      size: 'large',
      timer: '0'
    }
    this.minesweeper = new Minesweeper()
  }
  render () {
    let elem
    if (this.state.field === undefined) {
      elem = <NewGame newGameCallback={(size) => this.newGame(size)} />
    } else {
      let field = this.state.field.map((row, rowIdx) =>
        <div className={`r${rowIdx}`} key={`${rowIdx}`}>
          {row.map((square, colIdx) =>
            <div className={`square-${square} r${rowIdx} c${colIdx}`} key={`${rowIdx}${colIdx}`}
              onClick={e => this.pick(colIdx, rowIdx)}
              onContextMenu={e => {
                this.flag(colIdx, rowIdx)
                e.preventDefault()
              }}
              onDoubleClick={e => {
                this.forcePick(colIdx, rowIdx)
                e.preventDefault()
              }} />
          )}
        </div>
      )

      elem = <div className='mineField'>
        <div className='statusRow'>
          <Counter value='10' />
          <div className={'smiley-' + this.state.smiley}
            onMouseDown={e => this.poke()} onMouseUp={e => this.reset()}
            onClick={e => this.newGame(this.state.size)} />
          <Timer ref={t => { this.timer = t }} value={this.state.timer} />
        </div>
        <div className='field' onClick={e => this.timer.start()} onMouseDown={e => this.shock()}
          onMouseUp={e => this.reset()}>
          {field}
        </div>
      </div>
    }

    return <div className='container'>
      <div className='title'>Minesweeper</div>
      {elem}
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
    this.setState({ size: size })
    this.minesweeper.newGame(size)
      .then(field => this.setState({ field: field }))
  }

  flag (x, y) {
    this.minesweeper.flag(x, y)
      .then(field => this.setState({ field: field }))
  }

  pick (x, y) {
    this.minesweeper.pick(x, y)
      .then(resp => this.setState({ field: resp.field }))
  }

  forcePick (x, y) {
    this.minesweeper.forcePick(x, y)
      .then(resp => this.setState({ field: resp.field }))
  }
}
