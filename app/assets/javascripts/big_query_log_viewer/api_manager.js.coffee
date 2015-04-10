#= require ./components/tab_manager
#= require ./resources/tab_manager_resource
#= require ./resources/results_tab_resource
#= require ./resources/expansion_tab_resource
#= require ./resources/row_resource

window.BigQueryLogViewer ||= {}

TabManager = BigQueryLogViewer.TabManager
TabManagerResource = BigQueryLogViewer.TabManagerResource
ResultsTabResource = BigQueryLogViewer.ResultsTabResource
ExpansionTabResource = BigQueryLogViewer.ExpansionTabResource
RowResource = BigQueryLogViewer.RowResource

class BigQueryLogViewer.ApiManager
  constructor: (@projectNumber, @clientId, @tablePrefix, @rowsPerPage, @nearbyRows) ->
    config =
      'client_id': @clientId,
      'scope': 'https://www.googleapis.com/auth/bigquery'
      immediate: true

    # Perform authentication.
    gapi.auth.authorize(config, (result) ->
      if result.error
        config.immediate = false
        $('#authenticate-btn').show()
        $('#authenticate-btn').on 'click', ->
          gapi.auth.authorize(config, (result) ->
            unless result.error
              gapi.client.load('bigquery', 'v2')
              $('#application').fadeIn()
              $('#authenticate-btn').hide()
          )
      else
        gapi.client.load('bigquery', 'v2')
        $('#application').fadeIn()
        $('#authenticate-btn').hide()
    )

    # Create React elements.
    @tabManagerComponent = React.render(React.createElement(TabManager, {}), $('#application')[0])
    @tabManager = new TabManagerResource()
    @tabManagerComponent.setState
      tabManager: @tabManager

  tableRange: (startDate="CURRENT_TIMESTAMP()", endDate="CURRENT_TIMESTAMP()") -> 
    startDate = "TIMESTAMP('#{startDate} 00:00:00')" unless startDate == "CURRENT_TIMESTAMP()"
    endDate = "TIMESTAMP('#{endDate} 23:59:59')" unless endDate == "CURRENT_TIMESTAMP()"

    "(SELECT * FROM TABLE_DATE_RANGE(logs.#{@tablePrefix}_, #{startDate}, #{endDate}))"

  executeQuery: (query, config, success, error) ->
    console.log("Executing query: #{query}")
    config.maxResults ?= @rowsPerPage
    request = gapi.client.bigquery.jobs.query
      projectId: @projectNumber
      timeoutMs: 30000
      maxResults: config.maxResults
      query: query

    request.execute (response) ->
      if response.error
        error(response) if error?
      else
        success(response) if success?

  executeListQuery: (config, success, error) ->
    console.log("Executing list query")
    config.maxResults ?= @rowsPerPage
    request = gapi.client.bigquery.jobs.getQueryResults
      projectId: @projectNumber
      jobId: config.jobId
      timeoutMs: 30000
      maxResults: config.maxResults
      pageToken: config.pageToken

    request.execute (response) ->
      if response.error
        error(response) if error?
      else
        success(response) if success?
    
  search: (searchTerm, startDate, endDate) ->
    if (startDate == null) && (endDate != null) || (startDate != null) && (endDate == null)
      alert "Must fill in both or neither of start and end dates"
      return

    @tabManagerComponent.setState
      queryInProgress: true
      
    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@tableRange(startDate, endDate)} 
      where msg contains '#{searchTerm}'
      order by ts desc
      "

    @executeQuery(query, {}, (response) =>
      # Create new tab for the results.
      unless parseInt(response.totalRows) == 0
        rows = (new RowResource(r.f[0].v, r.f[4].v, r.f[3].v, r.f[1].v, r.f[2].v, r.f[5].v) for r in response.rows)
        newPage =
          rowData: rows
          pageToken: response.pageToken

        newPos = @tabManager.addTab(new ResultsTabResource(newPage, searchTerm, response.jobReference.jobId, startDate, endDate))
        @tabManager.setActiveTab(newPos)

      # Update view component.
      @tabManagerComponent.setState
        queryInProgress: false
        numReturnedResults: response.totalRows
        errorMessage: null
    , (response) =>
      @tabManagerComponent.setState
        queryInProgress: false
        numReturnedResults: 0
        errorMessage: response.message
    )

  nextPage: ->
    tab = @tabManager.activeTab()
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

  showProximity: (row) ->
    @tabManagerComponent.setState
      queryInProgress: true

    query = "
      SELECT ts, rid, sev, pid, host, msg
      FROM #{@tableRange(@tabManager.activeTab().startDate, @tabManager.activeTab().endDate)} 
      where host = '#{row.host}' 
      and pid = #{row.pid} 
      and rid between #{row.rid - @nearbyRows} and #{row.rid + @nearbyRows}
      order by ts, rid desc
      "

    maxResults = @nearbyRows * 2 + 1

    @executeQuery(query, {maxResults: @nearbyRows}, (response) =>
      # Create new tab for the expansion.
      rows = (new RowResource(r.f[0].v, r.f[4].v, r.f[3].v, r.f[1].v, r.f[2].v, r.f[5].v) for r in response.rows)
      page =
        rowData: rows
      newPos = @tabManager.addTab(new ExpansionTabResource(page, row.rid, row.msg))
      @tabManager.setActiveTab(newPos)

      # Update the view component.
      @tabManagerComponent.setState
        queryInProgress: false
        numReturnedResults: response.totalRows
        errorMessage: null
    , (reponse) =>
      console.log "ERROR: #{response.message}; entire response follows"
      console.log response
      alert "Error finding nearby rows; check console for more information"
    )