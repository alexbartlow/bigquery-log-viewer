###* @jsx React.DOM ###

#= require ../utils/query

#= require ./tab
#= require ./search_box
#= require ./search_status
#= require ./pagination

window.BigQueryLogViewer ||= {}

Tab = BigQueryLogViewer.Tab
SearchBox = BigQueryLogViewer.SearchBox
SearchStatus = BigQueryLogViewer.SearchStatus
Pagination = BigQueryLogViewer.Pagination

Query = BigQueryLogViewer.Query

BigQueryLogViewer.TabManager = React.createClass
  getInitialState: ->
    @query = new BigQueryLogViewer.Query(@props.projectId, @props.tablePrefix, @props.rowsPerPage)

    {
      tabs: []
      activeTabIndex: null
      queryInProgress: false
      numReturnedResults: null
      errorMessage: null
    }

  activeTab: ->
    @state.tabs[@state.activeTabIndex]

  findResultsTab: (term, startDate, endDate) ->
    (index for tab, index in @state.tabs when tab.type == 'results' && tab.term is term && tab.startDate is startDate && tab.endDate == endDate)[0]

  findExpansionTab: (rid) ->
    (index for tab, index in @state.tabs when tab.type == 'expansion' && tab.source == @activeTab() && tab.rid is rid)[0]

  handleSearch: (searchTerm, startDate, endDate) ->
    return if searchTerm == ''
    startDate = null if startDate == ''
    endDate = null if endDate == ''

    # Check that valid dates are entered.
    if (startDate == null) && (endDate != null) || (startDate != null) && (endDate == null)
      alert 'Must fill in both or neither of start and end dates'
      return
    
    # Check to see if we've already searched this term.
    if (foundTab = @findResultsTab(searchTerm, startDate, endDate)) != undefined
      @setState(activeTabIndex: foundTab)
      return

    @setState(queryInProgress: true)
    
    # Construct query.
    conds = [
      {
        field: 'msg'
        method: 'contains'
        value: searchTerm
      }
    ]
    query = @query.buildQuery(startDate, endDate, conds, 'ts desc')

    @query.executeQuery(query, {}, (response) =>
      # Create new tab for the results.
      unless parseInt(response.totalRows) == 0
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

        tab =
          id: randomId()
          type: 'results'
          rowData: rows
          pageToken: response.pageToken
          jobId: response.jobReference.jobId
          term: searchTerm
          startDate: startDate
          endDate: endDate

        position = if @state.activeTabIndex != null then @state.activeTabIndex + 1 else 0
        @state.tabs.splice(position, 0, tab)
        @setState(activeTabIndex: position)

      # Update view component.
      @setState
        queryInProgress: false
        numReturnedResults: response.totalRows
        errorMessage: null
    , (response) =>
      @setState
        queryInProgress: false
        numReturnedResults: 0
        errorMessage: response.message
    )

  handleShowProximity: (row) ->
    # Check to see if we've already queried this row proximity.
    if (foundTab = @findExpansionTab(row.rid)) != undefined
      @setState(activeTabIndex: foundTab)
      return

    @setState(queryInProgress: true)

    # Construct query.
    conds = [
      {
        field: 'host'
        method: 'equals'
        type: 'string'
        value: row.host
      }
      {
        field: 'pid'
        method: 'equals'
        type: 'int'
        value: row.pid
      }
      {
        field: 'rid'
        method: 'between'
        firstValue: row.rid - @props.rowsPerPage / 2
        secondValue: row.rid + @props.rowsPerPage / 2
      }
    ]
    query = @query.buildQuery(@activeTab().startDate, @activeTab().endDate, conds, 'ts, rid desc')

    @query.executeQuery(query, {maxResults: 101}, (response) =>
      # Create new tab for the expansion.
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
      tab =
        id: randomId()
        type: 'expansion'
        rowData: rows
        row: row
        source: @activeTab()
        term: @activeTab().term
      position = if @state.activeTabIndex != null then @state.activeTabIndex + 1 else 0
      @state.tabs.splice(position, 0, tab)

      # Update the view component.
      @setState
        activeTabIndex: position
        queryInProgress: false
        numReturnedResults: response.totalRows
        errorMessage: null
    , (reponse) =>
      console.log "ERROR: #{response.message}; entire response follows"
      console.log response
      alert 'Error finding nearby rows; check console for more information'
    )

  handleTabSwitch: (event) ->
    @setState(activeTabIndex: parseInt(event.dispatchMarker.split('tab-name-')[1]))

  handleTabDelete: (event) ->
    index = parseInt(event.dispatchMarker.split('tab-name-')[1])

    newIndex = 
      if index <= @state.activeTabIndex
        if @state.activeTabIndex > 0
          @state.activeTabIndex - 1
        else
          null
      else
        @state.activeTabIndex

    @state.tabs.splice(index, 1)
    @setState(activeTabIndex: newIndex)

  render: ->
    # Create tab list for pagination.
    pagination =
      for tab, index in @state.tabs
        title = tab.term
        title = "<i class='icon icon-external-link'></i> #{title}" if tab.type == 'expansion'

        {
          title: title
          active: index == @state.activeTabIndex
          key: "tab-name-#{index}"
        }

    tabs =
      for tab, index in @state.tabs
        <Tab key={"tab-#{tab.id}"} tab={tab} query={@query} visible={index == @state.activeTabIndex} handleShowProximity={@handleShowProximity} rowsPerPage={@props.rowsPerPage} />

    return (
      <div>
        <div>
          <SearchBox handleSearch={@handleSearch} />
          <SearchStatus queryInProgress={@state.queryInProgress} numReturnedResults={@state.numReturnedResults} errorMessage={@state.errorMessage} />
          <Pagination type={'top'} tabs={pagination} handleTabSwitch={@handleTabSwitch} handleTabDelete={@handleTabDelete} />
        </div>
        <div className={'tabs'}>
          {tabs}
        </div>
      </div>
    )