###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

SeverityCell = React.createClass
  getInitialState: ->
    {
      severity: @props.severity
    }

  severityClassMap: ->
    {
      "DEBUG": "label",
      "INFO": "label label-info",
      "WARNING": "label label-warning",
      "ERROR": "label label-important"
    }

  render: ->
    <td className='column-severity' data-severity={@props.severity}>
      <span className={@severityClassMap()[@props.severity]}>{@props.severity[0]}</span>
    </td>

BigQueryLogViewer.Row = React.createClass
  getInitialState: ->
    s = "000#{@props.row.timestamp.getMilliseconds()}"
    y = @props.row.timestamp.getFullYear()
    mo = ('0' + (@props.row.timestamp.getMonth() + 1)).slice(-2)
    d = ('0' + @props.row.timestamp.getDate()).slice(-2)
    h = ('0' + @props.row.timestamp.getHours()).slice(-2)
    mi = ('0' + @props.row.timestamp.getMinutes()).slice(-2)
    se = ('0' + @props.row.timestamp.getSeconds()).slice(-2)
    {
      tss: "#{y}-#{mo}-#{d} #{h}:#{mi}:#{se}"
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
        <span>{row.msg.substring(0,200)}<a href='#' className='expand-row' onClick={@handleShowMore}>... expand</a><span className='collapsed-string'>{row.msg.substring(200)}</span></span>
      else
        row.msg

    if @props.type == 'results'
      return (
        <tr>
          <td className='column-controls' onClick={@handleShowProximity}><i className='icon icon-external-link'></i></td>
          <td className='column-ts'>{@state.tss}<span className='ts-milliseconds'>.{@state.tsm}</span></td>
          <td className='column-host'>{row.host}</td>
          <td className='column-pid'>{row.pid}</td>
          <SeverityCell severity={row.severity}/>
          <td className='column-msg'><pre>{collapsedMsg}</pre></td>
        </tr>
      )
    else
      return (
        <tr className={'highlight-row' if @props.highlighted}>
          <td className='column-ts'>{@state.tss}<span className='ts-milliseconds'>.{@state.tsm}</span></td>
          <SeverityCell severity={row.severity}/>
          <td className='column-msg'><pre>{collapsedMsg}</pre></td>
        </tr>
      )