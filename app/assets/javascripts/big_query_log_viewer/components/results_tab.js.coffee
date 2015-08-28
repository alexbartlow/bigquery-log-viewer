###* @jsx React.DOM ###

#= require ./row

window.BigQueryLogViewer ||= {}

Row = BigQueryLogViewer.Row

BigQueryLogViewer.ResultsTab = React.createClass
  showNextPage: ->
    @props.showNextPage()

  showPrevPage: ->
    @props.showPrevPage()

  showPage: (event) ->
    @props.showPage(parseInt(event.dispatchMarker.split("pagination-link-")[1]))

  render: ->
    showProximity = @props.showProximity
    tab = @props.tab

    rows = []
    for row in tab.activePageData()
      rows.push <Row key={row.key()} tab={tab} row={row} showProximity={showProximity} />

    # Generate paginatoin.
    pagination = []

    if tab.hasPrevPage()
      pagination.push(
        <div key={"pagination-link-prev"}>
          <div onClick={@showPrevPage}>
            Prev
          </div>
        </div>
      )

    for page in [0..tab.numPages() - 1]
      tabClass =
        if page == tab.activePageIndex
          "tab-active"

      tabDivider =
        if pagination.length > 0
          <div className={"tab-divider"}>|</div>

      pagination.push(
        <div key={"pagination-link-" + page} className={tabClass}>
          {tabDivider}
          <div onClick={@showPage}>
            {page + 1}
          </div>
        </div>
      )

    if tab.hasNextPage()
      tabDivider =
        if pagination.length > 0
          <div className={"tab-divider"}>|</div>
      pagination.push(
        <div key={"pagination-link-next"}>
          {tabDivider}
          <div onClick={@showNextPage}>
            Next
          </div>
        </div>
      )

    return (
      <div>
        <table className="row-viewer">
          <tbody>
            {rows}
          </tbody>
        </table>
        <div className={"tabBar"}>
          {pagination}
        </div>
      </div>
    )