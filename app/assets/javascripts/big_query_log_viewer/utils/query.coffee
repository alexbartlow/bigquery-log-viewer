window.BigQueryLogViewer ||= {}

class BigQueryLogViewer.Query
  constructor: (@projectId, @tablePrefix, @rowsPerPage) ->
    #

  tableRange: (startDate="CURRENT_TIMESTAMP()", endDate="CURRENT_TIMESTAMP()") ->
    startDate = "TIMESTAMP('#{startDate} 00:00:00')" unless startDate == "CURRENT_TIMESTAMP()"
    endDate = "TIMESTAMP('#{endDate} 23:59:59')" unless endDate == "CURRENT_TIMESTAMP()"

    "(SELECT * FROM TABLE_DATE_RANGE(logs.#{@tablePrefix}_, #{startDate}, #{endDate}))"

  buildQuery: (startDate, endDate, conds, order) ->
    q = "SELECT ts, rid, sev, pid, host, msg FROM #{@tableRange(startDate, endDate)}"
    q = "#{q} WHERE #{conds.join(' AND ')}" if conds.length > 0
    q = "#{q} ORDER BY #{order}" if order
    q

  executeQuery: (query, config, success, error) ->
    console.log("Executing query: #{query}")
    config.maxResults ?= @rowsPerPage
    request = gapi.client.bigquery.jobs.query
      projectId: @projectId
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
      projectId: @projectId
      jobId: config.jobId
      timeoutMs: 30000
      maxResults: config.maxResults
      pageToken: config.pageToken

    request.execute (response) ->
      if response.error
        error(response) if error?
      else
        success(response) if success?