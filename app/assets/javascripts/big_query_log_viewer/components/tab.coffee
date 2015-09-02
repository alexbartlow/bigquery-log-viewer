###* @jsx React.DOM ###

#= require ./row

window.BigQueryLogViewer ||= {}

Row = BigQueryLogViewer.Row

BigQueryLogViewer.Tab = React.createClass
  getInitialState: ->
    {
      pages: [@props.tab.rowData]
      activePageIndex: 0
      pageToken: @props.tab.pageToken
      showBefore: false
      showAfter: false
    }

  handleNextPage: ->
    if @state.activePageIndex + 1 < @state.pages.length
      # Page has already been loaded, just activate it
      @setState(activePageIndex: @state.activePageIndex + 1)
    else if @state.pageToken
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

  handlePrevPage: ->
    @setState(activePageIndex: @state.activePageIndex - 1)

  handleShowPage: (event) ->
    @setState(activePageIndex: parseInt(event.dispatchMarker.split('pagination-link-')[1]))

  handleShowBefore: ->
    @setState(showBefore: true)

  handleShowAfter: ->
    @setState(showAfter: true)

  render: ->
    showProximity = @props.showProximity
    tab = @props.tab

    rows = []
    # Show all rows - this is a results tab.
    for row in @state.pages[@state.activePageIndex]
      rows.push <Row key={"#{row.pid}-#{row.rid}"} row={row} type={@props.tab.type} highlighted={@props.tab.rid == row.rid} handleShowProximity={@props.handleShowProximity} />

    beforeLink =
      if @props.tab.type == 'expansion'
        <a href='#' onClick={@handleShowBefore}>More</a>

    afterLink =
      if @props.tab.type == 'expansion'
        <a href='#' onClick={@handleShowAfter}>More</a>

    # Generate pagination if a results tab.
    if @props.tab.type == 'results'
      pagination = []

      if @state.activePageIndex > 0
        pagination.push(
          <div key={'pagination-link-prev'}>
            <div onClick={@handlePrevPage}>
              Prev
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
              {index + 1}
            </div>
          </div>
        )

      if @state.activePageIndex + 1 < @state.pages.length || @state.pageToken
        tabDivider = (<div className={'tab-divider'}>|</div>) if pagination.length > 0
            
        pagination.push(
          <div key={'pagination-link-next'}>
            {tabDivider}
            <div onClick={@handleNextPage}>
              Next
            </div>
          </div>
        )

    hiddenClass =
      unless @props.visible
        'hidden'

    return (
      <div className={hiddenClass}>
        {beforeLink}
        <table className={'row-viewer'}>
          <tbody>
            {rows}
          </tbody>
        </table>
        <div className={'tabBar'}>
          {pagination}
        </div>
        {afterLink}
      </div>
    )