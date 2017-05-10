import React from 'react'
import Counter from './counter'

export default class Timer extends React.Component {
  constructor (props) {
    super(props)
    this.state = {value: props.value}
  }

  render () {
    return <Counter value={this.state.value} />
  }

  start () {
    this.timerId = this.timerId || setInterval(() => this.tick(), 1000)
  }

  pause () {
    clearInterval(this.timerId)
    delete this.timerId
  }

  tick () {
    this.setState({ value: `${+this.state.value + 1}` })
    if (this.state.value === '999') this.pause()
  }
}
