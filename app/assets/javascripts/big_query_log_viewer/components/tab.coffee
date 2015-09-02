###* @jsx React.DOM ###

#= require ./row

window.BigQueryLogViewer ||= {}

Row = BigQueryLogViewer.Row

BigQueryLogViewer.Tab = React.createClass
  getInitialState: ->
    pageTitles =
      if @expansionTab()
        ['Target']
      else
        []

    {
      pages: [@props.tab.rowData]
      pageTitles: pageTitles
      activePageIndex: 0
      pageToken: @props.tab.pageToken
      showPrevLink: true
      showNextLink: true
      currentNextPage: 0
      currentPrevPage: 0
    }

  pageTitle: (index) ->
    @state.pageTitles[index] || (index + 1)

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

        @state.pages.push(rows)
        @state.pageTitles.push(@state.currentNextPage + 1)
        @setState(
          currentNextPage: @state.currentNextPage + 1
          activePageIndex: @state.pages.length - 1
        )

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

        @state.pages.unshift(rows)
        @state.pageTitles.unshift(@state.currentPrevPage + 1)
        @setState(
          currentPrevPage: @state.currentPrevPage + 1
          activePageIndex: 0
        )

      , (reponse) =>
        console.log "ERROR: #{response.message}; entire response follows"
        console.log response
        alert 'Error finding more context; check console for more information'
      )

  handleShowPage: (event) ->
    @setState(activePageIndex: parseInt(event.dispatchMarker.split('pagination-link-')[1]))

  handleShowBefore: ->
    @setState(showBefore: true)

  handleShowAfter: ->
    @setState(showAfter: true)

  render: ->
    showProximity = @props.showProximity
    tab = @props.tab

    rows =
      for row in @state.pages[@state.activePageIndex]
        <Row key={"#{row.pid}-#{row.rid}"} row={row} type={@props.tab.type} highlighted={@highlighted(row)} handleShowProximity={@props.handleShowProximity} />

    # Generate pagination.
    pagination = []

    if @state.activePageIndex > 0 || (@expansionTab() && @state.showPrevLink)
      pagination.push(
        <div key={'pagination-link-prev'}>
          <div onClick={@handlePrevPage}>
            {@prevTitle()}
          </div>
        </div>
      )

    for page, index in @state.pages
      tabClass =
        if index == @state.activePageIndex
          'tab-active' 

      tabDivider =
        if pagination.length > 0
          <div className={'tab-divider'}>|</div>

      pagination.push(
        <div key={"pagination-link-#{index}"} className={tabClass}>
          {tabDivider}
          <div onClick={@handleShowPage}>
            {@pageTitle(index)}
          </div>
        </div>
      )

    if @state.activePageIndex + 1 < @state.pages.length || (@resultsTab() && @state.pageToken) || (@expansionTab() && @state.showNextLink)
      tabDivider = (<div className={'tab-divider'}>|</div>) if pagination.length > 0
          
      pagination.push(
        <div key={'pagination-link-next'}>
          {tabDivider}
          <div onClick={@handleNextPage}>
            {@nextTitle()}
          </div>
        </div>
      )

    return (
      <div className={'hidden' unless @props.visible}>
        <table className={'row-viewer'}>
          <tbody>
            {rows}
          </tbody>
        </table>
        <div className={'tabBar'}>
          {pagination}
        </div>
      </div>
    )