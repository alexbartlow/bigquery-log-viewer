###* @jsx React.DOM ###

#= require ./resources/results_tab_resource
#= require ./resources/expansion_tab_resource
#= require ./resources/row_resource

#= require ./tab
#= require ./search_box
#= require ./search_status

window.BigQueryLogViewer ||= {}

ResultsTabResource = BigQueryLogViewer.ResultsTabResource
ExpansionTabResource = BigQueryLogViewer.ExpansionTabResource
RowResource = BigQueryLogViewer.RowResource

ExpansionTab = BigQueryLogViewer.ExpansionTab
ResultsTab = BigQueryLogViewer.ResultsTab
SearchBox = BigQueryLogViewer.SearchBox
SearchStatus = BigQueryLogViewer.SearchStatus

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
    return null unless @state.activeTabIndex
    @state.tabs[@state.activeTabIndex]

  addTab: (tab) ->
    if tab.expansionTab()
      tab.setSource(@activeTab())
    position = if @state.activeTabIndex then @state.activeTabIndex + 1 else 0
    @state.tabs.splice(position, 0, tab)
    position

  numTabs: ->
    @state.tabs.length

  findResultsTab: (term, startDate, endDate) ->
    (index for tab, index in @state.tabs when tab.resultsTab() && tab.term is term && tab.startDate is startDate && tab.endDate == endDate)[0]

  findExpansionTab: (rid) ->
    (index for tab, index in @state.tabs when tab.expansionTab() && tab.source == @activeTab() && tab.isHighlighted(rid))[0]

  handleSearch: (searchTerm, startDate, endDate) ->
    return if term == ""
    startDate = null if startDate == ""
    endDate = null if endDate == ""

    # Check that valid dates are entered.
    if (startDate == null) && (endDate != null) || (startDate != null) && (endDate == null)
      alert "Must fill in both or neither of start and end dates"
      return
    
    # Check to see if we've already searched this term.
    if (foundTab = @findResultsTab(term, startDate, endDate)) != undefined
      @setState(activeTabIndex: foundTab)
      return

    @setState(queryInProgress: true)
      
    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@query.tableRange(startDate, endDate)} 
      where msg contains '#{searchTerm}'
      order by ts desc
      "

    @query.executeQuery(query, {}, (response) =>
      # Create new tab for the results.
      unless parseInt(response.totalRows) == 0
        rows = (new RowResource(r.f[0].v, r.f[4].v, r.f[3].v, r.f[1].v, r.f[2].v, r.f[5].v) for r in response.rows)
        newPage =
          rowData: rows
          pageToken: response.pageToken

        newPos = @addTab(new ResultsTabResource(newPage, searchTerm, response.jobReference.jobId, startDate, endDate))
        @setState(activeTabIndex: newPos)

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

  handleNextPage: ->
    tab = @activeTab()
    if tab.nextPageLoaded()
      # Page has already been loaded, just activate it
      tab.nextPage()
      @tabManagerComponent.forceUpdate()
    else
      # Else load next page from Google.
      @executeListQuery({pageToken: tab.activePageToken(), jobId: tab.jobId}, (response) =>
        rows = (new RowResource(r.f[0].v, r.f[4].v, r.f[3].v, r.f[1].v, r.f[2].v, r.f[5].v) for r in response.rows)
        newPage =
          rowData: rows
          pageToken: response.pageToken
        tab.addPage(newPage)
        tab.nextPage()

        @tabManagerComponent.forceUpdate()
      , (response) =>
        console.log "ERROR: #{response.message}; entire response follows"
        console.log response
        alert "Error loading more rows; check console for more information"
      )

  handleShowProximity: (row) ->
    # Check to see if we've already queried this row proximity.
    if (foundTab = @findExpansionTab(row.rid)) != undefined
      @setState(activeTabIndex: foundTab)
      return

    @setState(queryInProgress: true)

    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@query.tableRange(@activeTab().startDate, @activeTab().endDate)} 
      where host = '#{row.host}' 
      and pid = #{row.pid} 
      and rid between #{row.rid - @nearbyRows} and #{row.rid + @nearbyRows}
      order by ts, rid desc
      "

    maxResults = @nearbyRows * 2 + 1

    @query.executeQuery(query, {maxResults: maxResults}, (response) =>
      # Create new tab for the expansion.
      rows = (new RowResource(r.f[0].v, r.f[4].v, r.f[3].v, r.f[1].v, r.f[2].v, r.f[5].v) for r in response.rows)
      page =
        rowData: rows
      newPos = @addTab(new ExpansionTabResource(page, row.rid, row.msg))
      @setState(activeTab: newPos)

      # Update the view component.
      @setState
        queryInProgress: false
        numReturnedResults: response.totalRows
        errorMessage: null
    , (reponse) =>
      console.log "ERROR: #{response.message}; entire response follows"
      console.log response
      alert "Error finding nearby rows; check console for more information"
    )

  handleTabSwitch: (event) ->
    @setState(activeTabIndex: parseInt(event.dispatchMarker.split("tab-name-")[1]))

  handleDeleteTab: (event) ->
    index = parseInt(event.dispatchMarker.split("tab-name-")[1])

    newIndex = @state.activeTabIndex
    if index <= @state.activeTabIndex
      newIndex = @state.activeTabIndex - 1
      if newIndex < 0
        newIndex = if @numTabs() > 0 newIndex = 0 then 0 else null

    @setState(
      tabs: @state.tabs.splice(index, 1)
      activeTabIndex: newIndex
    )

  render: ->
    # Create tab bar.
    tabNames = []
    for tab, index in @state.tabs
      tabClass = 
        if tab == @activeTab()
          'tab-active'

      tabDivider =
        if tabNames.length > 0
          <div className={"tab-divider"}>|</div>

      tabNames.push(
        <div key={"tab-name-" + index} className={tabClass}>
          {tabDivider}
          <div onClick={@handleTabSwitch}>
            {tab.title()}
          </div>
          <div>
            <a onClick={@handleDeleteTab}>X</a>
          </div>
        </div>
      )

    tabDiv =
      if tabNames.length > 0
        <div className="tabBar">
          {tabNames}
        </div>

    # Create tab to be displayed.
    activeTab =
      if (tab = @activeTab())
        <Tab key={"tab-#{index}"} tab={tab} query={@query} />

    return (
      <div>
        <div className={"fixed-top"}>
          <SearchBox handleSearch={@handleSearch} />
          <SearchStatus queryInProgress={@state.queryInProgress} numReturnedResults={@state.numReturnedResults} errorMessage={@state.errorMessage} />
          {tabDiv}
        </div>
        <div className={"tabs"}>
          {activeTab}
        </div>
      </div>
    )