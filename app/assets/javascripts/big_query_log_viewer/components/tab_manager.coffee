###* @jsx React.DOM ###

#= require ../utils/query

#= require ./tab
#= require ./search_box
#= require ./search_status

window.BigQueryLogViewer ||= {}

Tab = BigQueryLogViewer.Tab
SearchBox = BigQueryLogViewer.SearchBox
SearchStatus = BigQueryLogViewer.SearchStatus

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
      
    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@query.tableRange(startDate, endDate)} 
      where msg contains '#{searchTerm}'
      order by ts desc
      "

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

    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@query.tableRange(@activeTab().startDate, @activeTab().endDate)} 
      where host = '#{row.host}' 
      and pid = #{row.pid} 
      and rid between #{row.rid - @props.nearbyRows} and #{row.rid + @props.nearbyRows}
      order by ts, rid desc
      "

    maxResults = @props.nearbyRows * 2 + 1

    @query.executeQuery(query, {maxResults: maxResults}, (response) =>
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
        type: 'expansion'
        rowData: rows
        rid: row.rid
        msg: row.msg
        source: @activeTab()
      position = if @state.activeTabIndex != null then @state.activeTabIndex + 1 else 0
      @state.tabs.splice(position, 0, tab)
      @setState(activeTabIndex: position)

      # Update the view component.
      @setState
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

  handleDeleteTab: (event) ->
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
    # Create tab bar and tabs list.
    tabNames = []
    tabs = []
    for tab, index in @state.tabs
      tabClass = 
        if index == @state.activeTabIndex
          'tab-active'

      tabDivider =
        if tabNames.length > 0
          <div className={'tab-divider'}>|</div>

      title =
        if tab.type == 'results'
          if tab.startDate == null && tab.endDate == null
            "Search results: #{tab.term}"
          else
            "Search results: #{tab.term} (#{tab.startDate} to #{tab.endDate})"
        else
          "#{tab.msg.substr(0, 30)}..."

      tabNames.push(
        <div key={"tab-name-#{index}"} className={tabClass}>
          {tabDivider}
          <div onClick={@handleTabSwitch}>
            {title}
          </div>
          <div>
            <a onClick={@handleDeleteTab}>X</a>
          </div>
        </div>
      )

      tabs.push(
        <Tab key={"tab-#{index}"} tab={tab} query={@query} visible={index == @state.activeTabIndex} handleShowProximity={@handleShowProximity} />
      )
          
    tabDiv =
      if tabNames.length > 0
        <div className={'tabBar'}>
          {tabNames}
        </div>

    return (
      <div>
        <div className={'fixed-top'}>
          <SearchBox handleSearch={@handleSearch} />
          <SearchStatus queryInProgress={@state.queryInProgress} numReturnedResults={@state.numReturnedResults} errorMessage={@state.errorMessage} />
          {tabDiv}
        </div>
        <div className={'tabs'}>
          {tabs}
        </div>
      </div>
    )