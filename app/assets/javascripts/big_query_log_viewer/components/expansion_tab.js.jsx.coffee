###* @jsx React.DOM ###

#= require ./row

window.BigQueryLogViewer ||= {}

Row = BigQueryLogViewer.Row

window.BigQueryLogViewer.ExpansionTab = React.createClass
  showBefore: (event) ->
    event.preventDefault()
    @props.setShowBefore()

  showAfter: (event) ->
    event.preventDefault()
    @props.setShowAfter()

  render: ->
    tab = @props.tab

    # Determine which rows to show.
    firstRow = tab.highlightRid - 50
    if firstRow < tab.firstRid()
      firstRow = tab.firstRid()
    else
      expandBefore = true
    lastRow = tab.highlightRid + 50
    if lastRow > tab.lastRid()
      lastRow = tab.lastRid()
    else
      expandAfter = true

    beforeRows = []
    rows = []
    afterRows = []
    for row in tab.activePageData()
      highlighted = tab.isHighlighted(row.rid)
      if row.rid < firstRow
        beforeRows.push `<Row key={row.key()} tab={tab} row={row} />`
      else if row.rid > lastRow
        afterRows.push `<Row key={row.key()} tab={tab} row={row} />`
      else
        rows.push `<Row key={row.key()} tab={tab} row={row} />`

    beforeBlock =
      if tab.showBefore
        `<table className="row-viewer">
          <tbody>
            {beforeRows}
          </tbody>
        </table>`
      else if expandBefore
        `<a href="#" onClick={this.showBefore}>More</a>`
    
    afterBlock =
      if tab.showAfter
        `<table className="row-viewer">
          <tbody>
            {afterRows}
          </tbody>
        </table>`
      else if expandAfter
        `<a href="#" onClick={this.showAfter}>More</a>`

    `<div>
      {beforeBlock}
      <table className="row-viewer">
        <tbody>
          {rows}
        </tbody>
      </table>
      {afterBlock}
    </div>`