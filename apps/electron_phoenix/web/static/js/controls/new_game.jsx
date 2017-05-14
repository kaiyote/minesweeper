import React from 'react'

export default class NewGame extends React.Component {
  constructor (props) {
    super(props)
    this.newGameCallback = props.newGameCallback
  }

  render () {
    return <div>
      <div>New Game</div>
      <div>
        <a onClick={() => this.newGameCallback('small')}>Small</a>
        <a onClick={() => this.newGameCallback('medium')}>Medium</a>
        <a onClick={() => this.newGameCallback('large')}>Large</a>
      </div>
    </div>
  }
}
