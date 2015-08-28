###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.Row = React.createClass
  handleShowMore: (e) ->
    e.preventDefault()
    $(@getDOMNode()).find(".collapsed-string").show()
    $(@getDOMNode()).find(".expand-row").hide()
    
  handleShowProximity: (e) ->
    e.preventDefault()
    @props.showProximity(@props.row)
  
  render: ->
    row = @props.row

    collapsedMsg = 
      if row.longMsg()
        <span>{row.msgPrefix()}<a href="#" className="expand-row" onClick={@handleShowMore}>more</a><span className="collapsed-string">{row.msgSuffix()}</span></span>
      else
        row.msg

    highlightClass =
      if @props.tab.expansionTab() && @props.tab.isHighlighted(row.rid)
        'highlight-row'

    if @props.tab.resultsTab()
      return (
        <tr>
          <td className="column-controls" onClick={@handleShowProximity}><i className="icon icon-external-link"></i></td>
          <td className="column-ts">{row.tss()}<span className="ts-milliseconds">.{row.tsm()}</span></td>
          <td className="column-host">{row.host}</td>
          <td className="column-pid">{row.pid}</td>
          <td className="column-severity" data-severity={row.severity}>{row.severity}</td>
          <td className="column-msg"><pre>{collapsedMsg}</pre></td>
        </tr>
      )
    else
      return (
        <tr className={highlightClass}>
          <td className="column-ts">{row.tss()}<span className="ts-milliseconds">.{row.tsm()}</span></td>
          <td className="column-rid">{row.rid}</td>
          <td className="column-severity" data-severity={row.severity}>{row.severity}</td>
          <td className="column-msg"><pre>{collapsedMsg}</pre></td>
        </tr>
      )