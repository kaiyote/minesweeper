import React from 'react'

export default class Counter extends React.Component {
  render () {
    let value = this.props.value
    while (value.length < 3) {
      value = '0' + value
    }

    let digits = value.split('')
    return <div className='counter'>
      {digits.map((d, index) => <div key={d + index} className={'digit-' + d} />)}
    </div>
  }
}
