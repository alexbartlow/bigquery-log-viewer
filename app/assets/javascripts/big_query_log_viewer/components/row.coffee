###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.Row = React.createClass
  getInitialState: ->
    s = "000#{@props.row.timestamp.getMilliseconds()}"
    {
      tss: @props.row.timestamp.toString('dd MMM HH:mm:ss')
      tsm: s.substr(s.length - 3)
    }
  handleShowMore: (e) ->
    e.preventDefault()
    $(@getDOMNode()).find('.collapsed-string').show()
    $(@getDOMNode()).find('.expand-row').hide()
    
  handleShowProximity: (e) ->
    e.preventDefault()
    @props.handleShowProximity(@props.row)
  
  render: ->
    row = @props.row

    collapsedMsg = 
      if row.msg.length > 200
        <span>{row.msg.substring(0,200)}<a href='#' className='expand-row' onClick={@handleShowMore}>more</a><span className='collapsed-string'>{row.msg.substring(200)}</span></span>
      else
        row.msg

    highlightClass = 'highlight-row' if @props.highlighted

    if @props.type == 'results'
      return (
        <tr>
          <td className='column-controls' onClick={@handleShowProximity}><i className='icon icon-external-link'></i></td>
          <td className='column-ts'>{@state.tss}<span className='ts-milliseconds'>.{@state.tsm}</span></td>
          <td className='column-host'>{row.host}</td>
          <td className='column-pid'>{row.pid}</td>
          <td className='column-severity' data-severity={row.severity}>{row.severity}</td>
          <td className='column-msg'><pre>{collapsedMsg}</pre></td>
        </tr>
      )
    else
      return (
        <tr className={highlightClass}>
          <td className='column-ts'>{@state.tss}<span className='ts-milliseconds'>.{@state.tsm}</span></td>
          <td className='column-rid'>{@state.rid}</td>
          <td className='column-severity' data-severity={row.severity}>{row.severity}</td>
          <td className='column-msg'><pre>{collapsedMsg}</pre></td>
        </tr>
      )