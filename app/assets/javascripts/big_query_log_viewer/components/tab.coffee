###* @jsx React.DOM ###

#= require ./pagination
#= require ./row

window.BigQueryLogViewer ||= {}

Pagination = BigQueryLogViewer.Pagination
Row = BigQueryLogViewer.Row

BigQueryLogViewer.Tab = React.createClass
  getInitialState: ->
    {
      pages: [@props.tab.rowData]
      activePageIndex: 0
      pageToken: @props.tab.pageToken
      showPrevLink: true
      showNextLink: true
      currentNextPage: 0
      currentPrevPage: 0
    }

  resultsTab: ->
    @props.tab.type is 'results'

  expansionTab: ->
    @props.tab.type is 'expansion'

  highlighted: (row) ->
    @expansionTab() && @props.tab.row.rid is row.rid

  prevTitle: ->
    if @resultsTab() then 'Prev' else 'More'

  nextTitle: ->
    if @resultsTab() then 'Next' else 'More'

  handleNextPage: ->
    if @state.activePageIndex + 1 < @state.pages.length
      # Page has already been loaded, just activate it
      @setState(activePageIndex: @state.activePageIndex + 1)
    else if @resultsTab()
      # Else load next page from Google.
      @props.query.executeListQuery({pageToken: @state.pageToken, jobId: @props.tab.jobId}, (response) =>
        rows =
          for r in response.rows
            {
              timestamp: new Date(1000 * r.f[0].v)
              host: r.f[4].v
              pid: r.f[3].v
              rid: parseInt(r.f[1].v)
              severity: r.f[2].v
              msg: r.f[5].v
            }
        @state.pages.push(rows)
        @setState(
          pageToken: response.pageToken
          activePageIndex: @state.activePageIndex + 1
        )

      , (response) =>
        console.log "ERROR: #{response.message}; entire response follows"
        console.log response
        alert 'Error loading more rows; check console for more information'
      )
    else if @expansionTab()
      # Load additional context.
      startRow = @props.tab.row.rid + @props.rowsPerPage / 2 + @state.currentNextPage * @props.rowsPerPage
      endRow = @props.tab.row.rid + @props.rowsPerPage / 2 + (@state.currentNextPage + 1) * @props.rowsPerPage

      # Construct query.
      conds = [
        {
          field: 'host'
          method: 'equals'
          type: 'string'
          value: @props.tab.row.host
        }
        {
          field: 'pid'
          method: 'equals'
          type: 'int'
          value: @props.tab.row.pid
        }
        {
          field: 'rid'
          method: 'between'
          firstValue: startRow
          secondValue: endRow
        }
      ]
      query = @props.query.buildQuery(@props.tab.source.startDate, @props.tab.source.endDate, conds, 'ts, rid desc')

      @props.query.executeQuery(query, {maxResults: @props.rowsPerPage}, (response) =>
        # Mark no more next if there were no results.
        if parseInt(response.totalRows) == 0
          @setState(showNextLink: false)
          return

        # Create new page for the expansion.
        rows =
          for r in response.rows
            {
              timestamp: new Date(1000 * r.f[0].v)
              host: r.f[4].v
              pid: r.f[3].v
              rid: parseInt(r.f[1].v)
              severity: r.f[2].v
              msg: r.f[5].v
            }

        @state.pages[0] = @state.pages[0].concat(rows)
        @setState(currentNextPage: @state.currentNextPage + 1)

      , (reponse) =>
        console.log "ERROR: #{response.message}; entire response follows"
        console.log response
        alert 'Error finding more context; check console for more information'
      )

  handlePrevPage: ->
    if @resultsTab()
      @setState(activePageIndex: @state.activePageIndex - 1)
    else if @expansionTab()
      # Load additional context.
      startRow = @props.tab.row.rid - @props.rowsPerPage / 2 - @state.currentPrevPage * @props.rowsPerPage
      endRow = @props.tab.row.rid - @props.rowsPerPage / 2 - (@state.currentPrevPage + 1) * @props.rowsPerPage

      # Construct query.
      conds = [
        {
          field: 'host'
          method: 'equals'
          type: 'string'
          value: @props.tab.row.host
        }
        {
          field: 'pid'
          method: 'equals'
          type: 'int'
          value: @props.tab.row.pid
        }
        {
          field: 'rid'
          method: 'between'
          firstValue: startRow
          secondValue: endRow
        }
      ]
      query = @props.query.buildQuery(@props.tab.source.startDate, @props.tab.source.endDate, conds, 'ts, rid desc')

      @props.query.executeQuery(query, {maxResults: @props.rowsPerPage}, (response) =>
        # Mark no more prev if there were no results.
        if parseInt(response.totalRows) == 0
          @setState(showPrevLink: false)
          return

        # Create new page for the expansion.
        rows =
          for r in response.rows
            {
              timestamp: new Date(1000 * r.f[0].v)
              host: r.f[4].v
              pid: r.f[3].v
              rid: parseInt(r.f[1].v)
              severity: r.f[2].v
              msg: r.f[5].v
            }

        @state.pages[0] = rows.concat(@state.pages[0])
        @setState(currentPrevPage: @state.currentPrevPage + 1)

      , (reponse) =>
        console.log "ERROR: #{response.message}; entire response follows"
        console.log response
        alert 'Error finding more context; check console for more information'
      )

  handleShowPage: (event) ->
    @setState(activePageIndex: parseInt(event.dispatchMarker.split('pagination-link-')[1]))

  componentDidMount: ->
    if @expansionTab()
      window.requestAnimationFrame =>
        node = @getDOMNode()
        node.scrollTop = $(node).find('.highlight-row').offset().top

  componentDidUpdate: ->
    node = $(@getDOMNode())
    maxHeight = $(window).height() - node.offset().top - 40
    node.css('max-height', maxHeight)

  render: ->
    showProximity = @props.showProximity
    tab = @props.tab

    rows =
      for row in @state.pages[@state.activePageIndex]
        <Row key={"#{row.pid}-#{row.rid}"} row={row} type={@props.tab.type} highlighted={@highlighted(row)} handleShowProximity={@props.handleShowProximity} />

    # Generate pagination.
    if @resultsTab()
      pagination = []

      if @state.activePageIndex > 0 || (@expansionTab() && @state.showPrevLink)
        pagination.push(
          title: @prevTitle()
          active: false
          key: 'pagination-link-prev'
          handler: @handlePrevPage
        )

      for page, index in @state.pages
        pagination.push(
          title: (index + 1)
          active: index == @state.activePageIndex
          key: "pagination-link-#{index}"
          handler: @handleShowPage
        )

      if @state.activePageIndex + 1 < @state.pages.length || (@resultsTab() && @state.pageToken) || (@expansionTab() && @state.showNextLink)
        pagination.push(
          title: @nextTitle()
          active: false
          key: 'pagination-link-next'
          handler: @handleNextPage
        )

    head =
      if @resultsTab()
        <thead>
          <tr>
            <th></th>
            <th>Timestamp</th>
            <th>Host</th>
            <th>PID</th>
            <th>Severity</th>
            <th>Message</th>
          </tr>
        </thead>
      else
        <thead>
          <tr>
            <th>Timestamp</th>
            <th>RID</th>
            <th>Severity</th>
            <th>Message</th>
          </tr>
        </thead>

    pagination =
      if @resultsTab()
        <Pagination type={'inside'} tabs={pagination} handleTabSwitch={@handleTabSwitch} />

    showMoreTop =
      if @expansionTab() && @state.showPrevLink
        <a href={'#'} onClick={@handlePrevPage}>More</a>

    showMoreBottom =
      if @expansionTab() && @state.showNextLink
        <a href={'#'} onClick={@handleNextPage}>More</a>

    return (
      <div className={'hidden' unless @props.visible}>
        {showMoreTop}
        <table className={'table row-viewer'}>
          {head}
          <tbody>
            {rows}
          </tbody>
        </table>
        {pagination}
        {showMoreBottom}
      </div>
    )